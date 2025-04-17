resource "aws_launch_template" "eks_lt" {
  name_prefix   = "eks-node-"
  image_id      = data.aws_ami.eks_worker.id
  instance_type = "t3a.medium"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 50    # Custom volume size (50GB)
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  # This user_data calls the bootstrap script on the instance.
  # It is essential so that the node joins the cluster.
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -ex
    /etc/eks/bootstrap.sh ${aws_eks_cluster.dev.name}
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "eks-node"
    }
  }
}

# Data source for the latest EKS worker node AMI
data "aws_ami" "eks_worker" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.dev.version}-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["602401143452"]  # Amazon's official EKS AMI account
}
