variable "aws_region" { type = string; default = "ap-south-1" }
variable "project_name" { type = string; default = "travelmemory" }
variable "vpc_cidr" { type = string; default = "10.20.0.0/16" }
variable "public_subnet_cidr" { type = string; default = "10.20.1.0/24" }
variable "private_subnet_cidr" { type = string; default = "10.20.2.0/24" }
variable "instance_type" { type = string; default = "t3.micro" }
variable "key_name" { type = string; description = "Existing EC2 key-pair name in the selected region" }
variable "admin_cidr" { type = string; description = "Administrator public IP in CIDR form, for example 203.0.113.10/32" }
variable "app_port" { type = number; default = 3000 }
