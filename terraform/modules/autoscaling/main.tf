resource "aws_launch_template" "eks_worker" {
  name_prefix   = "${var.node_group_name}-lt-"
  image_id      = var.worker_ami_id        # EKS-optimized AMI for your region
  instance_type = var.instance_type        # Single instance type

  # User data boots the node with the cluster name and sets extra kubelet arguments.
  user_data = base64encode(<<EOF
#!/bin/bash
/etc/eks/bootstrap.sh ${var.cluster_name} --kubelet-extra-args '--node-labels=eks.amazonaws.com/nodegroup=${var.node_group_name}'
EOF
  )
}

resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.desired_capacity
    min_size     = var.min_size
    max_size     = var.max_size
  }

  # Use the custom launch template that now does NOT include an instance profile.
  launch_template {
    id      = aws_launch_template.eks_worker.id
    version = "$Latest"
  }

  tags = {
    Name = var.node_group_name
  }
}

