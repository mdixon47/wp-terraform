# Wordpress Terraform Solution Project version 1.0
## Date October 9, 2024
 

# Introduction
To create a Terraform solution that provisions an EC2 instance to serve as a WordPress webserver with a MySQL database, we will need to use various AWS resources. This solution will include an EC2 instance, a MySQL RDS database, security groups, and necessary IAM roles.

# Assumptions
- The instance will be in a public subnet for internet access.
- The RDS database will be in a private subnet for security.
- The security group will allow HTTP (port 80) and SSH access to the EC2 instance.
- The EC2 instance will run WordPress using Apache, PHP, and connect to the RDS MySQL database