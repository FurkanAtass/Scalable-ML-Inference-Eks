########################
# Cluster Autoscaler IRSA
########################

# AWS account ID (used to build OIDC provider ARN when needed)
data "aws_caller_identity" "current" {}

locals {
  cluster_oidc_issuer_without_scheme = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
}

# IAM policy for Cluster Autoscaler
resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "ClusterAutoscalerPolicy-${var.cluster_name}"
  description = "Permissions for Kubernetes Cluster Autoscaler"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeInstances",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "ec2:DescribeAvailabilityZones",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      }
    ]
  })
}

# IRSA role for Cluster Autoscaler service account kube-system/cluster-autoscaler
resource "aws_iam_role" "cluster_autoscaler_irsa" {
  name = "ClusterAutoscalerIRSA-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.cluster_oidc_issuer_without_scheme}"
        }
        Condition = {
          StringEquals = {
            "${local.cluster_oidc_issuer_without_scheme}:aud" = "sts.amazonaws.com",
            "${local.cluster_oidc_issuer_without_scheme}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler_attach" {
  role       = aws_iam_role.cluster_autoscaler_irsa.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}