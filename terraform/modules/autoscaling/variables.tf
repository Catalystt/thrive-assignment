variable "cluster_name" {
  description = "The name of the EKS cluster to attach the node group"
  type        = string
}

variable "node_group_name" {
  description = "The name of the EKS node group"
  type        = string
}

variable "node_role_arn" {
  description = "IAM role ARN for the node group (worker nodes)"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where the node group will be deployed"
  type        = list(string)
}

variable "desired_capacity" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of nodes in the node group"
  type        = number
  default     = 3
}

variable "instance_types" {
  description = "List of EC2 instance types for the node group"
  type        = list(string)
  default     = ["t3.micro"]
}
