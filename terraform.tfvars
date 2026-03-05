# ACM certificate (ISSUED)
alb_acm_cert_arn = "arn:aws:acm:ap-northeast-2:004932907894:certificate/1f667fa4-126d-47dc-aafa-5b933521d3c5"

# ALB 접근 허용 CIDR (검증 단계에서는 전체 허용)
alb_allowed_cidrs = ["0.0.0.0/0"]

# Target Group health check
alb_health_check_path = "/health"

# TLS policy
alb_ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"
