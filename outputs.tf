# Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.usinsa.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.usinsa.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value = [
    aws_subnet.usinsa_public_2a.id,
    aws_subnet.usinsa_public_2b.id
  ]
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value = [
    aws_subnet.usinsa_private_2a.id,
    aws_subnet.usinsa_private_2b.id
  ]
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.usinsa_igw.id
}

output "s3_endpoint_id" {
  description = "S3 VPC Endpoint ID"
  value       = aws_vpc_endpoint.usinsa_s3_endpoint.id
}