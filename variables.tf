# ============================================================
# Terraform Variables - Main Configuration
# ============================================================

# ============================================================
# 1. AWS Region
# ============================================================
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

# ============================================================
# 2. VPC CIDR
# ============================================================
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

# ============================================================
# 3. Project Name (통합 - project 변수 제거)
# ============================================================
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "usinsa"
}

# project 변수는 project_name으로 통합
# 기존 코드 호환성을 위해 local에서 처리 가능

# ============================================================
# 4. Kubernetes Cluster Name
# ============================================================
variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "usinsa-cluster"
}

# ============================================================
# ALB Variables
# ============================================================

variable "alb_acm_cert_arn" {
  description = "ACM certificate ARN (ISSUED) for HTTPS listener"
  type        = string
  default     = ""  # 기본값 추가 - terraform plan 시 에러 방지

  # 사용 시 terraform.tfvars에서 설정:
  # alb_acm_cert_arn = "arn:aws:acm:ap-northeast-2:123456789012:certificate/xxx"
}

variable "alb_allowed_cidrs" {
  description = "CIDRs allowed to access ALB (80/443). Recommend your public IP/32"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "alb_health_check_path" {
  description = "ALB target group health check path"
  type        = string
  default     = "/health"
}

variable "alb_ssl_policy" {
  description = "ELB SSL policy name"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}


