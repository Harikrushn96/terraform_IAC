# Create AWS EKS Node Group - Public
resource "aws_eks_node_group" "eks_ng_public" {
  cluster_name    = aws_eks_cluster.tf_cluster.name
  node_group_name = "eks-nodegrp"
  node_role_arn   = aws_iam_role.eks_nodegroup_role.arn
  subnet_ids = [
    aws_subnet.public-1a.id,
    aws_subnet.public-1b.id
  ]


  ami_type       = "AL2_x86_64"
  capacity_type  = "ON_DEMAND"
  disk_size      = 20
  instance_types = ["t3.medium"]


  remote_access {
    ec2_ssh_key = "ggwp"
  }

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 3
  }

  # Desired max percentage of unavailable worker nodes during node group update.
  update_config {
    max_unavailable = 1
    #max_unavailable_percentage = 50    # ANY ONE TO USE
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks_nodegroup_role-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_nodegroup_role-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_nodegroup_role-AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    Name = "Public-Node-Group"
  }
}