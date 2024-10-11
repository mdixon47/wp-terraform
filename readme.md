# Wordpress Terraform Solution Project version 1.0
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


# Terraform Errors

```

```



# Terraform Solution

https://chatgpt.com/share/67086247-054c-8011-a001-d723aa082d4a


# Breakdown of the Terraform Solution

## Breakdown of the Solution:

 1. Custom VPC:
        
      -  The custom VPC (aws_vpc.wordpress_vpc) is created with a CIDR block of 10.0.0.0/16. This VPC is necessary to house the subnets, and RDS instances must exist within a VPC.

 2. Subnets:

      -  Two subnets (aws_subnet.wordpress_subnet_1 and aws_subnet.wordpress_subnet_2) are created in different Availability Zones. This ensures high availability, which is often a requirement for RDS.

 3. DB Subnet Group:

      -  The aws_db_subnet_group.wordpress_db_subnet_group associates the two subnets with the RDS instance. RDS instances require a subnet group to ensure proper placement in the VPC. This prevents the "No default subnet" error by explicitly defining the subnets.

 4. Security Group:

     -  The security group (aws_security_group.wordpress_db_sg) allows traffic on port 3306, which is the default for MySQL. In production, you should restrict the ingress rule to specific IPs or security groups instead of using 0.0.0.0/0 (which allows access from anywhere).

 5. RDS Instance:

    - The aws_db_instance.wordpress_db resource creates a MySQL RDS instance using the DB subnet group and the security group. This ensures that the RDS instance is placed within the defined subnets of the VPC and prevents any subnet-related errors.

 6. Additional Steps (If Needed):

    - VPC NAT Gateways: If your RDS instance needs to communicate with the internet (e.g., for backups or updates), ensure your VPC includes an internet gateway and NAT gateways for public and private subnets, respectively.

    Restricting Security Group: Replace "0.0.0.0/0" in the ingress rule of the security group with specific IP ranges to secure your database instance.
    
    



