# ============================================================
# WireGuard VPN Configuration for usinsa VPC
# 
# 기존 main.tf의 VPC, Subnet, Security Group과 연동
# ============================================================

# ============================================================
# Data Source: 기존 VPC 참조
# ============================================================
data "aws_vpc" "usinsa" {
  filter {
    name   = "tag:Name"
    values = [var.project_name]
  }
}

# ============================================================
# Data Source: 기존 Public Subnet 참조 (AZ별)
# ============================================================
data "aws_subnet" "usinsa_public_2a" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-public-2a"]
  }
}

data "aws_subnet" "usinsa_public_2b" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-public-2b"]
  }
}

# ============================================================
# Security Group for WireGuard VPN
# ============================================================
resource "aws_security_group" "wireguard" {
  name        = "${var.project_name}-wireguard-sg"
  description = "Security group for WireGuard VPN servers"
  vpc_id      = data.aws_vpc.usinsa.id

  tags = {
    Name = "${var.project_name}-wireguard-sg"
  }
}

# ============================================================
# Security Group Rule: SSH Access
# ============================================================
resource "aws_security_group_rule" "wireguard_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.wireguard.id
  description       = "SSH access for WireGuard bastion"
}

# ============================================================
# Security Group Rule: WireGuard UDP Port
# ============================================================
resource "aws_security_group_rule" "wireguard_udp" {
  type              = "ingress"
  from_port         = 51820
  to_port           = 51820
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.wireguard.id
  description       = "WireGuard VPN port"
}

# ============================================================
# Security Group Rule: VPC Internal Communication
# ============================================================
resource "aws_security_group_rule" "wireguard_internal" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.wireguard.id
  description       = "Internal VPC communication"
}

# ============================================================
# Security Group Rule: Outbound All Traffic
# ============================================================
resource "aws_security_group_rule" "wireguard_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.wireguard.id
  description       = "All outbound traffic"
}

# ============================================================
# Data Source: Amazon Linux 2023 AMI
# ============================================================
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ============================================================
# Elastic IP for WireGuard AZ2a
# ============================================================
resource "aws_eip" "wireguard_2a" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-wireguard-eip-2a"
  }

  depends_on = [data.aws_subnet.usinsa_public_2a]
}

# ============================================================
# Elastic IP for WireGuard AZ2b
# ============================================================
resource "aws_eip" "wireguard_2b" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-wireguard-eip-2b"
  }

  depends_on = [data.aws_subnet.usinsa_public_2b]
}

# ============================================================
# EC2 Instance: WireGuard Bastion in AZ2a
# ============================================================
resource "aws_instance" "wireguard_2a" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  # 기존 VPC의 Public Subnet 사용
  subnet_id = data.aws_subnet.usinsa_public_2a.id

  # WireGuard Security Group 적용
  vpc_security_group_ids = [aws_security_group.wireguard.id]

  # WireGuard 자동 설치 스크립트
user_data = base64encode(file("${path.module}/wireguard_setup.sh"))

  tags = {
    Name = "${var.project_name}-wireguard-bastion-2a"
  }

  depends_on = [aws_security_group_rule.wireguard_udp]
}

# ============================================================
# EC2 Instance: WireGuard Bastion in AZ2b
# ============================================================
resource "aws_instance" "wireguard_2b" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  # 기존 VPC의 Public Subnet 사용
  subnet_id = data.aws_subnet.usinsa_public_2b.id

  # WireGuard Security Group 적용
  vpc_security_group_ids = [aws_security_group.wireguard.id]

  # WireGuard 자동 설치 스크립트
user_data = base64encode(file("${path.module}/wireguard_setup.sh"))

  tags = {
    Name = "${var.project_name}-wireguard-bastion-2b"
  }

  depends_on = [aws_security_group_rule.wireguard_udp]
}

# ============================================================
# Elastic IP Association: AZ2a
# ============================================================
resource "aws_eip_association" "wireguard_2a" {
  instance_id   = aws_instance.wireguard_2a.id
  allocation_id = aws_eip.wireguard_2a.id
}

# ============================================================
# Elastic IP Association: AZ2b
# ============================================================
resource "aws_eip_association" "wireguard_2b" {
  instance_id   = aws_instance.wireguard_2b.id
  allocation_id = aws_eip.wireguard_2b.id
}

# ============================================================
# Outputs: VPN Server Information
# ============================================================

output "wireguard_2a_info" {
  value = {
    instance_id  = aws_instance.wireguard_2a.id
    private_ip   = aws_instance.wireguard_2a.private_ip
    elastic_ip   = aws_eip.wireguard_2a.public_ip
    public_dns   = aws_instance.wireguard_2a.public_dns
    availability_zone = aws_instance.wireguard_2a.availability_zone
  }
  description = "WireGuard Bastion Information for AZ2a"
}

output "wireguard_2b_info" {
  value = {
    instance_id  = aws_instance.wireguard_2b.id
    private_ip   = aws_instance.wireguard_2b.private_ip
    elastic_ip   = aws_eip.wireguard_2b.public_ip
    public_dns   = aws_instance.wireguard_2b.public_dns
    availability_zone = aws_instance.wireguard_2b.availability_zone
  }
  description = "WireGuard Bastion Information for AZ2b"
}

output "wireguard_sg_id" {
  value       = aws_security_group.wireguard.id
  description = "WireGuard Security Group ID"
}

output "wireguard_ssh_2a" {
  value       = "ssh -i your-key.pem ec2-user@${aws_eip.wireguard_2a.public_ip}"
  description = "SSH Connection String for AZ2a"
}

output "wireguard_ssh_2b" {
  value       = "ssh -i your-key.pem ec2-user@${aws_eip.wireguard_2b.public_ip}"
  description = "SSH Connection String for AZ2b"
}
