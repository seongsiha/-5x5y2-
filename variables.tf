# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "usinsa"
}

variable "project" {
  description = "Project name for resource naming"
  type        = string
  default     = "usinsa"
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "usinsa-cluster"
}

############################################
# ALB variables (추가)
############################################

variable "alb_acm_cert_arn" {
  description = "ACM certificate ARN (ISSUED) for HTTPS listener"
  type        = string
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
