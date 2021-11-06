# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY A SINGLE EC2 INSTANCE
# This template runs a simple "Hello, World" web server on a single EC2 Instance
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  # This module is now only being tested with Terraform 0.15.x. However, to make upgrading easier, we are setting
  # 0.12.26 as the minimum version, as that version added support for required_providers with source URLs, making it
  # forwards compatible with 0.15.x code.
  required_version = ">= 0.12.26"
}

# ------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ------------------------------------------------------------------------------

provider "aws" {
  region = "us-west-1"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATING VPC and subnet-0ee3d055206b9e1d6" and subnet-0f1bc2ee816672c73
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_vpc" "ownvpc" { 
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "code-challenge-vpc"
  }
}

resource "aws_subnet" "private-1" {
  vpc_id     = aws_vpc.ownvpc.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "us-west-1b"
  tags = {
    Name = "code-challenge-private-subnet-1"
  }
}

resource "aws_subnet" "private-2" {
    vpc_id = aws_vpc.ownvpc.id
    cidr_block = "192.168.1.0/24"
    availability_zone = "us-west-1c"
  tags = {
    Name = "code-challenge-private-subnet-2"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATING SUBNET GROUP, each DB Subnet Group should have at least one subnet for every Availability Zone in a given Region.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_db_subnet_group" "code-challenge-subnet-group" {
	name = "code-challenge-subnet-group"
	subnet_ids = ["${aws_subnet.private-1.id}","${aws_subnet.private-2.id}"]
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A SINGLE EC2 INSTANCE IN A PRIVATE VPC
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_instance" "example" {
  # Ubuntu Server 18.04 LTS (HVM), SSD Volume Type in us-east-2
  ami                    = "ami-053ac55bdcfe96e85"
  instance_type          = "t2.micro"
  subnet_id		 = "subnet-0ee3d055206b9e1d6"

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, Clippers" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF
  tags = {
    Name = "code-challenge-instance"
  }
}
# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE RDS DATABASE IN ANOTHER PROVATE VPC
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_rds_cluster" "default" {
  cluster_identifier      = "code-challenge-aurora-cluster"
  engine                  = "aurora-mysql"
  engine_version          = "5.7.mysql_aurora.2.03.2"
  availability_zones      = ["us-west-1b", "us-west-1c"]
  database_name           = "mydb"
  master_username         = "foo"
  master_password         = "bar12345678"
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  db_subnet_group_name = "code-challenge-subnet-group"
}

 
