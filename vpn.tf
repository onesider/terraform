terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_key_pair" "aws_key" {
  key_name   = "{terraform.workspace}-aws-key"
  public_key = file("~/.ssh/onesiderAWS.pub")
}

# VPC
resource "aws_vpc" "redteam-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "redteam-vpc"
  }
}

# Subnet
resource "aws_subnet" "redteam-sub-public1" {
  vpc_id                  = aws_vpc.redteam-vpc.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "redteam-sub-public1"
  }
}

resource "aws_subnet" "redteam-sub-private1" {
  vpc_id            = aws_vpc.redteam-vpc.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "redteam-sub-private1"
  }
}

#Internet Gateway
resource "aws_internet_gateway" "redteam-igw" {
  vpc_id = aws_vpc.redteam-vpc.id
  tags = {
    Name = "redteam-igw"
  }
}

resource "aws_eip" "nat" {
  vpc = true
}

# NAT GateWay
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.redteam-sub-public1.id

  tags = {
    Name = "redteam-NAT"
  }
}

# Routing Table
resource "aws_route_table" "redteam-public1" {
  vpc_id = aws_vpc.redteam-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.redteam-igw.id
  }
  tags = {
    Name = "redteam-public1"
  }
}

resource "aws_route_table_association" "redteam-routing-public1" {
  subnet_id      = aws_subnet.redteam-sub-public1.id
  route_table_id = aws_route_table.redteam-public1.id
}


# Private Routing Table
resource "aws_route_table" "redteam-private1" {
  vpc_id = aws_vpc.redteam-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "redteam-private1"
  }
}

resource "aws_route_table_association" "redteam-routing-private1" {
  subnet_id      = aws_subnet.redteam-sub-private1.id
  route_table_id = aws_route_table.redteam-private1.id
}
