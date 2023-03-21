# EKS cluster

resource "aws_eks_cluster" "tf_cluster" {
  name     = "tf_eks"
  role_arn = aws_iam_role.eks_master_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.private-1a.id,
      aws_subnet.private-1b.id,
      aws_subnet.public-1a.id,
      aws_subnet.public-1b.id
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_master_role-AmazonEKSClusterPolicy]
}