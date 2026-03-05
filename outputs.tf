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

############################################
# ALB Outputs (추가/수정)
############################################

output "alb_dns_name" {
  description = "ALB DNS name (AWS 제공 도메인)"
  value       = aws_lb.this.dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.this.arn
}

output "alb_zone_id" {
  description = "Route53 Alias에 쓰는 ALB Hosted Zone ID"
  value       = aws_lb.this.zone_id
}

output "alb_sg_id" {
  description = "ALB Security Group ID"
  value       = aws_security_group.alb.id
}

output "alb_tg_arn" {
  description = "Target Group ARN"
  value       = aws_lb_target_group.eks.arn
}

output "alb_listener_http_arn" {
  description = "HTTP Listener ARN"
  value       = aws_lb_listener.http.arn
}

output "alb_listener_https_arn" {
  description = "HTTPS Listener ARN"
  value       = aws_lb_listener.https.arn
}

output "verify_http_url" {
  description = "HTTP 테스트 URL (80 -> 443 리다이렉트 확인용)"
  value       = "http://${aws_lb.this.dns_name}${var.alb_health_check_path}?x=1"
}

output "verify_https_url" {
  description = "HTTPS 테스트 URL (인증서/리스너 확인용)"
  value       = "https://${aws_lb.this.dns_name}${var.alb_health_check_path}?x=1"
}

output "cloudfront_domain" {
  description = "CloudFront 접속 도메인"
  value       = aws_cloudfront_distribution.this.domain_name
}
