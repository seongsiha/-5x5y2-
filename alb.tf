############################################
# ALB (Internet-facing) - auto attach to VPC
############################################

resource "random_id" "alb_suffix" {
  byte_length = 3
}

locals {
  alb_suffix = lower(random_id.alb_suffix.hex)

  alb_name = "${var.project_name}-alb-${local.alb_suffix}"
  sg_name  = "${var.project_name}-alb-sg-${local.alb_suffix}"
  tg_name  = "${var.project_name}-tg-${local.alb_suffix}"
}

############################
# Security Group for ALB
############################
resource "aws_security_group" "alb" {
  name        = local.sg_name
  description = "ALB Security Group"
  vpc_id      = aws_vpc.usinsa.id

  tags = {
    Name = local.sg_name
  }
}

resource "aws_security_group_rule" "alb_ingress_80" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.alb_allowed_cidrs
  description       = "Allow HTTP to ALB"
}

resource "aws_security_group_rule" "alb_ingress_443" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.alb_allowed_cidrs
  description       = "Allow HTTPS to ALB"
}

resource "aws_security_group_rule" "alb_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound"
}

############################
# Target Group (for EKS / service)
############################
resource "aws_lb_target_group" "eks" {
  name        = local.tg_name
  target_type = "ip"
  protocol    = "HTTP"
  port        = 80
  vpc_id      = aws_vpc.usinsa.id

  health_check {
    enabled  = true
    protocol = "HTTP"
    path     = var.alb_health_check_path
    matcher  = "200-399"
  }

  tags = {
    Name = local.tg_name
  }
}

############################
# ALB
############################
resource "aws_lb" "this" {
  name               = local.alb_name
  load_balancer_type = "application"
  internal           = false

  subnets = [
    aws_subnet.usinsa_public_2a.id,
    aws_subnet.usinsa_public_2b.id
  ]

  security_groups = [aws_security_group.alb.id]

  tags = {
    Name = local.alb_name
  }

  depends_on = [
    aws_internet_gateway.usinsa_igw,
    aws_route_table_association.public_2a,
    aws_route_table_association.public_2b
  ]
}

############################
# Listener :80 -> :443 redirect
############################
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_301"
      host        = "#{host}"
      path        = "/#{path}"
      query       = "#{query}"
    }
  }
}

############################
# Listener :443 -> forward to TG
############################
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = var.alb_ssl_policy
  certificate_arn = var.alb_acm_cert_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.eks.arn
  }
}
