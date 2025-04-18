resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.dev.name
  node_group_name = "dev-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [
    aws_subnet.public_subnet[0].id,
    aws_subnet.public_subnet[1].id
  ]

  scaling_config {
    desired_size = 3
    max_size     = 6
    min_size     = 1
  }

  capacity_type = "ON_DEMAND"

  launch_template {
    id      = aws_launch_template.eks_lt.id
    version = "$Latest"
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEKS_EBS_CSI_Driver_Policy
  ]

  tags = {
    Name = "dev-node-group"
  }
}

resource "aws_eks_addon" "ebs" {
  cluster_name = aws_eks_cluster.dev.name
  addon_name   = "aws-ebs-csi-driver"
  
  # This setting resolves any conflicts by overwriting the existing add-on configuration.
  resolve_conflicts = "OVERWRITE"

  tags = {
    Name = "dev-node-group"
  }

  # Adding an explicit dependency ensures that the node group is active before the add-on is installed.
  depends_on = [aws_eks_node_group.nodes]
}

resource "aws_iam_role" "eks_node_role" {
  name = "eks_node_role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [{
      "Effect": "Allow",
      "Principal": {
          "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
  }]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.id
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.id
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.id
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_EBS_CSI_Driver_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.eks_node_role.id
}
