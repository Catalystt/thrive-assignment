output "node_group_name" {
  description = "The created node group name"
  value       = aws_eks_node_group.this.node_group_name
}
