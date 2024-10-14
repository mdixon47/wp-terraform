# Wordpress Terraform Solution Project version 1.1
### Date October 9, 2024
 

# Introduction
To create a Terraform solution that provisions an EC2 instance to serve as a WordPress webserver with a MySQL database, we will need to use various AWS resources. This solution will include an EC2 instance, a MySQL RDS database, security groups, and necessary IAM roles.

# Assumptions
- The instance will be in a public subnet for internet access.
- The RDS database will be in a private subnet for security.
- The security group will allow HTTP (port 80) and SSH access to the EC2 instance.
- The EC2 instance will run WordPress using Apache, PHP, and connect to the RDS MySQL database

# Terraform Configuration
The Terraform configuration will include the following resources:
- AWS provider configuration
- VPC with public and private subnets
- Internet Gateway and Route Table for public subnet
- NAT Gateway and Route Table for private subnet
- Security Groups for EC2 instance and RDS database
- IAM roles for EC2 instance
- EC2 instance with user data script to install WordPress
- RDS MySQL database

# Terraform Commands
To create the infrastructure using Terraform, you can run the following commands:

```
terraform init
terraform plan
terraform apply
```

# Terraform Setup
To set up Terraform for this project, you will need to install Terraform on your local machine and configure the AWS provider with your credentials. You can follow the official Terraform documentation for installation and setup instructions.

- AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- VPC Creation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
- EC2 Instance: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
- RDS Database: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance
- Security Groups: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
- IAM Roles: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
- User Data: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#user_data
- WordPress installation aws: https://aws.amazon.com/getting-started/hands-on/host-wordpress-website/
- Output: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#outputs





    




    



