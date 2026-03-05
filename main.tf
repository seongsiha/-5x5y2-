# Terraform Configuration for AWS Infrastructure
# Provider configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

# VPC
resource "aws_vpc" "usinsa" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "usinsa"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "usinsa_igw" {
  vpc_id = aws_vpc.usinsa.id

  tags = {
    Name = "usinsa-igw"
  }
}

# Elastic IP (NAT용)
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

# Public Subnets
resource "aws_subnet" "usinsa_public_2a" {
  vpc_id            = aws_vpc.usinsa.id
  cidr_block        = "10.0.0.0/20"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name                                        = "usinsa-public-2a"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

resource "aws_subnet" "usinsa_public_2b" {
  vpc_id            = aws_vpc.usinsa.id
  cidr_block        = "10.0.16.0/20"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name                                        = "usinsa-public-2b"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

# Private Subnets
resource "aws_subnet" "usinsa_private_2a" {
  vpc_id            = aws_vpc.usinsa.id
  cidr_block        = "10.0.128.0/20"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name                                        = "usinsa-private-2a"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

resource "aws_subnet" "usinsa_private_2b" {
  vpc_id            = aws_vpc.usinsa.id
  cidr_block        = "10.0.144.0/20"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name                                        = "usinsa-private-2b"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

# Public Route Table
resource "aws_route_table" "usinsa_public_rt" {
  vpc_id = aws_vpc.usinsa.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.usinsa_igw.id
  }

  tags = {
    Name = "usinsa-public-rt"
  }
}

# Private Route Table 1
resource "aws_route_table" "usinsa_private_rt1" {
  vpc_id = aws_vpc.usinsa.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "usinsa-private-rt1"
  }
}

# Private Route Table 2
resource "aws_route_table" "usinsa_private_rt2" {
  vpc_id = aws_vpc.usinsa.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "usinsa-private-rt2"
  }
}

# Route Table Associations - Public Subnets
resource "aws_route_table_association" "public_2a" {
  subnet_id      = aws_subnet.usinsa_public_2a.id
  route_table_id = aws_route_table.usinsa_public_rt.id
}

resource "aws_route_table_association" "public_2b" {
  subnet_id      = aws_subnet.usinsa_public_2b.id
  route_table_id = aws_route_table.usinsa_public_rt.id
}

# Route Table Associations - Private Subnets

resource "aws_route_table_association" "private_2a" {
  subnet_id      = aws_subnet.usinsa_private_2a.id
  route_table_id = aws_route_table.usinsa_private_rt1.id
}

resource "aws_route_table_association" "private_2b" {
  subnet_id      = aws_subnet.usinsa_private_2b.id
  route_table_id = aws_route_table.usinsa_private_rt2.id
}

# VPC Endpoint for S3
resource "aws_vpc_endpoint" "usinsa_s3_endpoint" {
  vpc_id       = aws_vpc.usinsa.id
  service_name = "com.amazonaws.ap-northeast-2.s3"

  route_table_ids = [
    aws_route_table.usinsa_public_rt.id,
    aws_route_table.usinsa_private_rt1.id,
    aws_route_table.usinsa_private_rt2.id
  ]

  tags = {
    Name = "usinsa-endpoint"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.usinsa_public_2a.id

  tags = {
    Name = "${var.project}-nat"
  }

  depends_on = [aws_internet_gateway.usinsa_igw]
}

