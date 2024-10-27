provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "MyNewApp-VPC"
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "MyNewApp-Public-Subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "MyNewApp-IGW"
  }
}

# Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "MyNewApp-Public-Route-Table"
  }
}

resource "aws_route_table_association" "public_subnet_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group for Web Server
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "MyNewApp-Web-SG"
  }
}

# EC2 Instance for Web Application
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI in us-east-1
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.web_sg.name]

  # User Data to install and run Apache with custom page content
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              echo "<html><body><h1>Welcome to MyNewApp!</h1><p>This is a web application deployed with Terraform.</p></body></html>" > /var/www/html/index.html
              systemctl start httpd
              systemctl enable httpd
              EOF

  tags = {
    Name = "MyNewApp-Web-Instance"
  }
}
