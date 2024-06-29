terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "pwc_project"

    workspaces {
      name = "project_one"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "VPC"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_cidr
  availability_zone = var.availability_zone
  tags = {
    Name = "Public_Subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "IGW"
  }
}

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "Public_Route"
  }
}

resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "SG"
  }
}

resource "aws_eip" "eip" {}

resource "aws_instance" "ec2" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  availability_zone           = var.availability_zone
  associate_public_ip_address = true
  key_name                    = "terraform"

  tags = {
    Name = "EC2"
  }
}

resource "aws_eip_association" "eip_association" {
  instance_id   = aws_instance.ec2.id
  allocation_id = aws_eip.eip.id
}

resource "aws_route53_zone" "domain" {
  name = "corstat.net"
}

resource "aws_route53_record" "main" {
  zone_id = aws_route53_zone.domain.zone_id
  name    = "corstat.net"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.eip.public_ip]
}

resource "aws_route53_record" "alias" {
  zone_id = aws_route53_zone.domain.zone_id
  name    = "www.corstat.net"
  type    = "A"
  
  alias {
    name    = aws_route53_record.main.fqdn
    zone_id = aws_route53_record.main.zone_id
    evaluate_target_health = true
  }
}