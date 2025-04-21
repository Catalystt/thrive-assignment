output "cluster_id" {
  description = "The EKS cluster ID"
  value       = aws_eks_cluster.this.id
}
