variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_role_arn" {
  description = "IAM role ARN for the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for EKS cluster networking"
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Whether to enable public access to the EKS endpoint"
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Whether to enable private access to the EKS endpoint"
  type        = bool
  default     = false
}
