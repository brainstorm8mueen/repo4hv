provider "aws" { region = var.aws_region }

data "aws_availability_zones" "available" { state = "available" }
data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"]
  filter { name = "name"; values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"] }
  filter { name = "virtualization-type"; values = ["hvm"] }
}

locals { tags = { Project = var.project_name, ManagedBy = "Terraform" } }

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = merge(local.tags, { Name = "${var.project_name}-vpc" })
}
resource "aws_internet_gateway" "main" { vpc_id = aws_vpc.main.id; tags = merge(local.tags, { Name = "${var.project_name}-igw" }) }
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id; cidr_block = var.public_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = merge(local.tags, { Name = "${var.project_name}-public" })
}
resource "aws_subnet" "private" {
  vpc_id = aws_vpc.main.id; cidr_block = var.private_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = merge(local.tags, { Name = "${var.project_name}-private" })
}
resource "aws_eip" "nat" { domain = "vpc"; tags = local.tags; depends_on = [aws_internet_gateway.main] }
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id; subnet_id = aws_subnet.public.id
  tags = merge(local.tags, { Name = "${var.project_name}-nat" })
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route { cidr_block = "0.0.0.0/0"; gateway_id = aws_internet_gateway.main.id }
  tags = merge(local.tags, { Name = "${var.project_name}-public-rt" })
}
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route { cidr_block = "0.0.0.0/0"; nat_gateway_id = aws_nat_gateway.main.id }
  tags = merge(local.tags, { Name = "${var.project_name}-private-rt" })
}
resource "aws_route_table_association" "public" { subnet_id = aws_subnet.public.id; route_table_id = aws_route_table.public.id }
resource "aws_route_table_association" "private" { subnet_id = aws_subnet.private.id; route_table_id = aws_route_table.private.id }

resource "aws_security_group" "web" {
  name = "${var.project_name}-web-sg"; vpc_id = aws_vpc.main.id
  ingress { description = "SSH from administrator"; from_port = 22; to_port = 22; protocol = "tcp"; cidr_blocks = [var.admin_cidr] }
  ingress { description = "TravelMemory application"; from_port = var.app_port; to_port = var.app_port; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"] }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
  tags = merge(local.tags, { Name = "${var.project_name}-web-sg" })
}
resource "aws_security_group" "db" {
  name = "${var.project_name}-db-sg"; vpc_id = aws_vpc.main.id
  ingress { description = "SSH only from web server"; from_port = 22; to_port = 22; protocol = "tcp"; security_groups = [aws_security_group.web.id] }
  ingress { description = "MongoDB only from web server"; from_port = 27017; to_port = 27017; protocol = "tcp"; security_groups = [aws_security_group.web.id] }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
  tags = merge(local.tags, { Name = "${var.project_name}-db-sg" })
}
resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-ec2-role"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole" }] })
  tags = local.tags
}
resource "aws_iam_role_policy_attachment" "ssm" { role = aws_iam_role.ec2.name; policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" }
resource "aws_iam_instance_profile" "ec2" { name = "${var.project_name}-profile"; role = aws_iam_role.ec2.name }
resource "aws_instance" "web" {
  ami = data.aws_ami.ubuntu.id; instance_type = var.instance_type; subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]; key_name = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2.name
  root_block_device { encrypted = true; volume_size = 12; volume_type = "gp3" }
  metadata_options { http_tokens = "required" }
  tags = merge(local.tags, { Name = "${var.project_name}-web" })
}
resource "aws_instance" "db" {
  ami = data.aws_ami.ubuntu.id; instance_type = var.instance_type; subnet_id = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.db.id]; key_name = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2.name
  root_block_device { encrypted = true; volume_size = 12; volume_type = "gp3" }
  metadata_options { http_tokens = "required" }
  tags = merge(local.tags, { Name = "${var.project_name}-db" })
}
