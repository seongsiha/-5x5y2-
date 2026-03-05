# ============================================================
# EKS Node Group
# 
# remote_access 블록 추가로 SSH 접근 활성화
# ============================================================

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.project_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  
  subnet_ids = [
    aws_subnet.usinsa_private_2a.id,
    aws_subnet.usinsa_private_2b.id
  ]
  
  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.medium"]
  disk_size      = 20

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 4
  }

  update_config {
    max_unavailable = 1
  }

  # ============================================================
  # 🆕 SSH 접근 설정 추가!
  # ============================================================
  remote_access {
    # SSH 키 연결 (key-pair.tf에서 생성한 키)
    ec2_ssh_key = aws_key_pair.main.key_name
    
    # SSH 접근 허용할 Security Group
    # → WireGuard Bastion에서만 SSH 접근 가능
    source_security_group_ids = [aws_security_group.wireguard.id]
  }

  tags = {
    Name      = "${var.project_name}-node-group"
    Project   = var.project_name
    ManagedBy = "terraform"
  }

  depends_on = [
    aws_iam_role_policy_attachment.worker_node,
    aws_iam_role_policy_attachment.cni,
    aws_iam_role_policy_attachment.ecr
  ]
}

# ============================================================
# Outputs: Node Group Information
# ============================================================
output "eks_node_group_name" {
  value       = aws_eks_node_group.this.node_group_name
  description = "EKS Node Group Name"
}

output "eks_node_group_status" {
  value       = aws_eks_node_group.this.status
  description = "EKS Node Group Status"
}

