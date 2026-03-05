# ============================================================
# EKS Cluster
# ============================================================
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = "1.31"  # 수정: 1.34 → 1.31 (현재 최신 안정 버전)
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.usinsa_private_2a.id,
      aws_subnet.usinsa_private_2b.id
    ]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  # 로깅 활성화 (선택사항)
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = {
    Name      = var.cluster_name
    Project   = var.project_name
    ManagedBy = "terraform"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# ============================================================
# EKS Cluster Outputs
# ============================================================
output "eks_cluster_name" {
  value       = aws_eks_cluster.this.name
  description = "EKS Cluster Name"
}

output "eks_cluster_endpoint" {
  value       = aws_eks_cluster.this.endpoint
  description = "EKS Cluster Endpoint"
}

output "eks_cluster_version" {
  value       = aws_eks_cluster.this.version
  description = "EKS Cluster Version"
}
