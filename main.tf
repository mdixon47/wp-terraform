terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "wordpress-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "wordpress-public-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-server-sg"
  }
}

resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysql-rds-sg"
  }
}

resource "aws_db_instance" "wordpress_db" {
  allocated_storage      = 20
  engine                 = "mysql"
  instance_class         = "db.t2.micro"
  identifier             = "wordpressdb"
  username               = "admin"
  password               = "yourpassword"
  parameter_group_name   = "default.mysql8.0"
  vpc_security_group_ids = ["sg-12345678"]                             # Update this with your security group ID
  db_subnet_group_name   = aws_db_subnet_group.my_db_subnet_group.name # Reference the subnet group
  skip_final_snapshot    = true
}

resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "my-subnet-group"
  subnet_ids = ["subnet-12345678", "subnet-87654321"] # Add your subnet IDs here
}


resource "aws_instance" "wordpress" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI (update as needed)
  instance_type = "t2.micro"
  key_name      = "my-key-pair" # Replace with your key pair

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "wordpress-server"
  }

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    amazon-linux-extras install -y php7.4
    yum install -y php-mysqlnd

    systemctl start httpd
    systemctl enable httpd

    cd /var/www/html
    wget https://wordpress.org/latest.tar.gz
    tar -xzf latest.tar.gz
    mv wordpress/* .
    rm -rf wordpress latest.tar.gz

    # Create wp-config.php
    cp wp-config-sample.php wp-config.php
    sed -i 's/database_name_here/wordpressdb/' wp-config.php
    sed -i 's/username_here/admin/' wp-config.php
    sed -i 's/password_here/password123/' wp-config.php
    sed -i 's/localhost/${aws_db_instance.wordpress_db.endpoint}/' wp-config.php

    chown -R apache:apache /var/www/html
    systemctl restart httpd
  EOF
}


output "ec2_public_ip" {
  value = aws_instance.wordpress.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.wordpress_db.endpoint
}



