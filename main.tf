provider "aws" {
  region = "var.region"
}

resource "aws_vpc" "test" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "test-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.test.id
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.test.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.test.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone
  tags = {
    Name = "private-subnet"
  }

  resource "aws_route_table" "public" {
    vpc_id = aws_vpc.test.id
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.igw.id
    }
  }

  resource "aws_route_table_association" "route-association" {
    subnet_id      = aws_subnet.public.id
    route_table_id = aws_route_table.public.id
  }

  resource "aws_security_group" "web-sg" {
    name   = "web-sg"
    vpc_id = aws_vpc.test.id

    ingress {
      description = "allow HTTP Request"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_block  = ["0.0.0.0/0"]
    }

    ingress {
      description = "allow HTTPS Request"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_block  = ["0.0.0.0/0"]
    }

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = ""
      cidr_block  = ["0.0.0.0/0"]
    }

    tags = {
      Name = "web-sg"
    }
  }

  resource "aws_instance" "web" {
    ami                         = var.ami_id
    instance_type               = var.instance_type
    subnet_id                   = aws_subnet.public.id
    vpc_security_group_ids      = [aws_security_group.web-sg.id]
    key_name                    =  var.key_name
    associate_public_ip_address = true

    user_data = <<-EOF
      #!/bin/sh
      yum update -y
      yum install -y httpd mod_ssl openssl
      systemctl enable httpd
      systemctl start httpd

      EOF

    tags = {
      Name = "web-server"
    }
  }

  
  
  


