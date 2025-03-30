terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 4.16"
        }
    }
    required_version = ">=1.2.0"
}

provider "aws" {
    region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1b"
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
}

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
}

resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "instance1" {
  ami           = "ami-071226ecf16aa7d96"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_a.id
  security_groups = [aws_security_group.web_sg.id]
  tags = {
    Name = var.instance1_name
  }
}

resource "aws_instance" "instance2" {
  ami           = "ami-071226ecf16aa7d96"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_b.id
  security_groups = [aws_security_group.web_sg.id]
  tags = {
    Name = var.instance2_name
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

resource "aws_db_instance" "rds" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  name                 = "assignment4terraformdb"
  username             = "admin"
  password             = "assignment4"
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}

output "instance1_public_ip" {
  description = "Public ip for EC2 Instance1"  
  value = aws_instance.instance1.public_ip
}

output "instance2_public_ip" {
  description = "Public ip for EC2 Instance2"   
  value = aws_instance.instance2.public_ip
}

output "rds_endpoint" {
  description = "endpoint for the RDS database"   
  value = aws_db_instance.rds.endpoint
}
