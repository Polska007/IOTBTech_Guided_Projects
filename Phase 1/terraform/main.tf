terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# ---------- AMI: Ubuntu 24.04 ----------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# ---------- Network ----------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project_name}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project_name}-public-subnet" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ---------- Security groups ----------
resource "aws_security_group" "control" {
  name        = "${var.project_name}-control-sg"
  description = "SSH to the Ansible control node from my IP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-control-sg" }
}

resource "aws_security_group" "managed" {
  name        = "${var.project_name}-managed-sg"
  description = "SSH from control node only, app port from anywhere"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH from control node"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.control.id]
  }

  ingress {
    description = "Application port"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-managed-sg" }
}

# ---------- Key pair ----------
resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-key"
  public_key = file(pathexpand(var.public_key_path))
}


# ---------- Instances ----------
resource "aws_instance" "control" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  private_ip             = cidrhost(var.subnet_cidr, 10)
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.control.id]

  # Installs Ansible on first boot, so no local-exec bootstrap is needed
  user_data = <<-EOT
    #!/bin/bash
    set -eux
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y ansible git
  EOT

  tags = { Name = "${var.project_name}-control" }
}

resource "aws_instance" "managed" {
  count                  = var.managed_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  private_ip             = cidrhost(var.subnet_cidr, 11 + count.index)
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.managed.id]


  tags = { Name = "${var.project_name}-managed-${count.index + 1}" }
}
