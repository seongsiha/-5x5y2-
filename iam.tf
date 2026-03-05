# ============================================================
# EKS IAM Roles
# 
# Role 이름을 프로젝트별 고유 이름으로 설정
# (AWS 계정 내 충돌 방지)
# ============================================================

# ============================================================
# EKS Cluster Role
# ============================================================
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.project_name}-eks-cluster-role"  # 프로젝트별 고유 이름

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name      = "${var.project_name}-eks-cluster-role"
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ============================================================
# EKS Node Role
# ============================================================
resource "aws_iam_role" "eks_node_role" {
  name = "${var.project_name}-eks-node-role"  # 프로젝트별 고유 이름

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name      = "${var.project_name}-eks-node-role"
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "worker_node" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
