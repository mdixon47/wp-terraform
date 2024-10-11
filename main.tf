terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

# Create a custom VPC
resource "aws_vpc" "wordpress_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "WordPress VPC"
  }
}

# Create two subnets in different Availability Zones
resource "aws_subnet" "wordpress_subnet_1" {
  vpc_id            = aws_vpc.wordpress_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a" # Update based on your region

  tags = {
    Name = "WordPress Subnet 1"
  }
}

resource "aws_subnet" "wordpress_subnet_2" {
  vpc_id            = aws_vpc.wordpress_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b" # Update based on your region

  tags = {
    Name = "WordPress Subnet 2"
  }
}

# Create a DB Subnet Group
resource "aws_db_subnet_group" "wordpress_db_subnet_group" {
  name       = "wordpress-db-subnet-group"
  subnet_ids = [aws_subnet.wordpress_subnet_1.id, aws_subnet.wordpress_subnet_2.id]

  tags = {
    Name = "WordPress DB Subnet Group"
  }
}

# Create a security group for the RDS instance
resource "aws_security_group" "wordpress_db_sg" {
  vpc_id = aws_vpc.wordpress_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict this in production to your IP or private CIDR
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WordPress DB Security Group"
  }
}

# Create the RDS DB Instance using the DB subnet group
resource "aws_db_instance" "wordpress_db" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  identifier             = "wordpressdb"
  username               = "admin"
  password               = "password" # Replace with a secure password
  parameter_group_name   = "default.mysql8.0"
  db_subnet_group_name   = aws_db_subnet_group.wordpress_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.wordpress_db_sg.id]
  skip_final_snapshot    = true

  tags = {
    Name = "WordPress DB Instance"
  }
}
# Create EC2 instance and install WordPress
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

# Output the RDS instance endpoint information

output "ec2_public_ip" {
  value = aws_instance.wordpress.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.wordpress_db.endpoint
}


