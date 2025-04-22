variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDRs for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDRs for private subnets"
  type        = list(string)
}

# New variables for VPC endpoint configuration
variable "aws_region" {
  description = "AWS region for VPC endpoints"
  type        = string
  default     = "ca-central-1"
}

variable "vpc_endpoint_subnet_type" {
  description = "Specifies whether VPC endpoints should be deployed in 'public' or 'private' subnets."
  type        = string
  default     = "public"
}
