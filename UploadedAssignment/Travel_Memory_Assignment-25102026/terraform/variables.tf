variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project_name" {
  type    = string
  default = "travelmemory"
}

variable "vpc_cidr" {
  type    = string
  default = "172.31.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "172.31.16.0/20"
}

variable "private_subnet_cidr" {
  type    = string
  default = "172.31.32.0/20"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  type        = string
  description = "Existing EC2 key-pair name in the selected AWS region"
}

variable "admin_cidr" {
  type        = string
  description = "Administrator public IP in CIDR format, for example 203.0.113.10/32"
}

variable "app_port" {
  type    = number
  default = 3000
}
