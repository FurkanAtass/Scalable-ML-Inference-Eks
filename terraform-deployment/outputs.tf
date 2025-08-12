########################
# Outputs
########################

output "cluster_autoscaler_role_arn" {
  description = "IAM role ARN for Cluster Autoscaler IRSA (annotate the SA with this)"
  value       = aws_iam_role.cluster_autoscaler_irsa.arn
}