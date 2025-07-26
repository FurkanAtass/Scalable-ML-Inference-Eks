variable "cluster_name" {
  type        = string
  default     = "swin-tiny-eks-cluster"
  description = "The name of the EKS cluster"
}

variable "vpc_name" {
  type        = string
  default     = "swin-tiny-eks-vpc"
  description = "The name of the VPC"
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "The region of the EKS cluster"
}

variable "iam_user_name" {
  type        = string
  default     = "Admin"
  description = "The name of the IAM user"
}