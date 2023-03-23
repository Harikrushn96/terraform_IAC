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


resource "aws_security_group" "worker_sg" {
  name        = "worker-sg"
  description = "security group for all worker node in cluser"
  vpc_id      = aws_vpc.tf_vpc.id


  tags = {
    "name"                         = "worker-sg"
    "kubernetes.io/cluster/tf_eks" = "owned"
  }
}

resource "aws_security_group_rule" "node_internal" {
  description              = "Allow communicate to each other"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  security_group_id        = aws_security_group.worker_sg.id
  source_security_group_id = aws_security_group.worker_sg.id
}

resource "aws_security_group_rule" "node_cluster_inbound" {
  description              = "Allow worker kubelete and pods to receive communication"
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker_sg.id
  source_security_group_id = aws_security_group.master_sg.id
}


