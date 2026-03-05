resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = "1.34"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.usinsa_private_2a.id,
      aws_subnet.usinsa_private_2b.id
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}
