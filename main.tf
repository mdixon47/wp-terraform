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
  region = "us-east-1" # Replace with your desired AWS region
}

# VPC
resource "aws_vpc" "wordpress_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Subnet
resource "aws_subnet" "wordpress_subnet" {
  vpc_id            = aws_vpc.wordpress_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a" # Changed from us-west-1a to us-east-1a
}

resource "aws_subnet" "wordpress_subnet_1" {
  vpc_id            = aws_vpc.wordpress_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b" # Make sure this is correct
}

resource "aws_subnet" "wordpress_subnet_2" {
  vpc_id            = aws_vpc.wordpress_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1c" # This is already correct
}



# Internet Gateway
resource "aws_internet_gateway" "wordpress_igw" {
  vpc_id = aws_vpc.wordpress_vpc.id
}

# Route Table
resource "aws_route_table" "wordpress_route_table" {
  vpc_id = aws_vpc.wordpress_vpc.id
}

# Route Table Association
resource "aws_route_table_association" "wordpress_subnet_association" {
  subnet_id      = aws_subnet.wordpress_subnet.id
  route_table_id = aws_route_table.wordpress_route_table.id
}


# Route to Internet Gateway
resource "aws_route" "wordpress_route" {
  route_table_id         = aws_route_table.wordpress_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.wordpress_igw.id
}

# Elastic IP
resource "aws_eip" "wordpress_ip_1" {
  instance = aws_instance.wordpress_instance_1.id
}

# Associate an Elastic IP with Instance 2
resource "aws_eip" "wordpress_ip_2" {
  instance = aws_instance.wordpress_instance_2.id
}



resource "aws_db_instance" "wordpress_db" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0.35"
  instance_class       = "db.t3.micro"
  identifier           = "wordpressdb"
  username             = "admin"
  password             = "password123"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
}

# Security group for the instances
resource "aws_security_group" "wordpress_sg" {
  vpc_id = aws_vpc.wordpress_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
    Name = "WordPress Security Group"
  }
}

# Look up the latest Ubuntu AMI (e.g., Ubuntu 20.04 LTS) in the current region
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's AWS account ID for Ubuntu AMIs

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# EC2 Instance 1 with Elastic IP, using Ubuntu AMI
resource "aws_instance" "wordpress_instance_1" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t3.micro"
  subnet_id       = aws_subnet.wordpress_subnet_1.id
  security_groups = [aws_security_group.wordpress_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y apache2 certbot python3-certbot-apache

              # Create a self-signed certificate or configure certbot
              sudo certbot --non-interactive --apache --agree-tos --email your-email@example.com -d yourdomain1.com

              # Modify the SSL configuration
              sudo sed -i '/^<\/VirtualHost>/i \\nSSLVerifyClient none\\nSSLVerifyDepth 1\\n' /etc/apache2/sites-enabled/000-default-le-ssl.conf
              
              # Restart Apache to apply changes
              sudo systemctl restart apache2

              # Mount shared volume
              sudo mkfs -t ext4 /dev/sdh
              sudo mkdir /mnt/shared
              sudo mount /dev/sdh /mnt/shared
              EOF

  tags = {
    Name = "WordPress Instance 1"
  }
}

# EC2 Instance 2 with Elastic IP, using Ubuntu AMI
resource "aws_instance" "wordpress_instance_2" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t3.micro"
  subnet_id       = aws_subnet.wordpress_subnet_2.id
  security_groups = [aws_security_group.wordpress_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y apache2 certbot python3-certbot-apache

              # Create a self-signed certificate or configure certbot
              sudo certbot --non-interactive --apache --agree-tos --email your-email@example.com -d yourdomain2.com

              # Modify the SSL configuration
              sudo sed -i '/^<\/VirtualHost>/i \\nSSLVerifyClient none\\nSSLVerifyDepth 1\\n' /etc/apache2/sites-enabled/000-default-le-ssl.conf
              
              # Restart Apache to apply changes

              # Mount shared volume
              sudo mkfs -t ext4 /dev/sdh
              sudo mkdir /mnt/shared
              sudo mount /dev/sdh /mnt/shared
              EOF

  tags = {
    Name = "WordPress Instance 2"
  }
}

# Elastic Load Balancer (ELB)
resource "aws_elb" "wordpress_elb" {
  name            = "wordpress-load-balancer"
  security_groups = [aws_security_group.wordpress_sg.id]
  subnets         = [aws_subnet.wordpress_subnet_1.id, aws_subnet.wordpress_subnet_2.id]

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  listener {
    instance_port      = 443
    instance_protocol  = "HTTPS"
    lb_port            = 443
    lb_protocol        = "HTTPS"
    ssl_certificate_id = "arn:aws:acm:us-east-1:211125385032:certificate/da5a6dd4-6b75-44ae-ac17-edba60dbf2ea"
  }

  health_check {
    target              = "HTTP:80/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  instances = [aws_instance.wordpress_instance_1.id, aws_instance.wordpress_instance_2.id]

  tags = {
    Name = "WordPress Load Balancer"
  }
}


# Optionally, configure DNS for the ELB
resource "aws_route53_record" "wordpress_elb_dns" {
  zone_id = "Z059195515TLG4WDKY4GB" # Replace with your Route53 hosted zone ID
  name    = "http://www.xspremier.com"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_elb.wordpress_elb.dns_name]
}

# Shared EBS Volummes

resource "aws_ebs_volume" "shared_volume" {
  availability_zone    = "us-east-1c"
  size                 = 100
  type                 = "io2"
  iops                 = 3000
  multi_attach_enabled = true
}

resource "aws_volume_attachment" "ebs_att_1" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.shared_volume.id
  instance_id = aws_instance.wordpress_instance_1.id
}

resource "aws_volume_attachment" "ebs_att_2" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.shared_volume.id
  instance_id = aws_instance.wordpress_instance_2.id
}



