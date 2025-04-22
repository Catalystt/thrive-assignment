variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "ca-central-1"
}

variable "alert_email" {
  description = "Email address to receive CloudWatch alerts"
  type        = string
}
