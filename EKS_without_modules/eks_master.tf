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
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks_master_role-AmazonEKSClusterPolicy]
}

resource "aws_security_group" "master_sg" {
  name        = "master-sg"
  description = "security group for master node"
  vpc_id      = aws_vpc.tf_vpc.id

  tags = {
    "name" = "master-sg"
  }
}

resource "aws_security_group_rule" "cluster_inbound" {
  description              = "Allow worker node to communicate with the cluster API"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.master_sg.id
  source_security_group_id = aws_security_group.worker_sg.id

}

resource "aws_security_group_rule" "cluster_outbound" {
  description              = "Allow cluster api to communicate with worker node"
  type                     = "egress"
  from_port                = 1024
  to_port                  = 65535
  protocol                 = "-1"
  security_group_id        = aws_security_group.master_sg.id
  source_security_group_id = aws_security_group.worker_sg.id
}


