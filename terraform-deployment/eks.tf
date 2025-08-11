module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.37.2"

  cluster_name    = var.cluster_name
  cluster_version = "1.33"

  # Optional
  cluster_endpoint_public_access = true
  enable_irsa = true
  # Optional: Adds the current caller identity as an administrator via cluster access entry
  # enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["g4dn.xlarge"]
  }

  eks_managed_node_groups = {
    node_group_1 = {
      name = "node-group-1"
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_NVIDIA"
      instance_types = ["g4dn.xlarge"]

      min_size     = 2
      max_size     = 5
      desired_size = 2
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

data "aws_iam_user" "admin" {
  user_name = var.iam_user_name
}

# Grant EKS cluster admin access via access entry
resource "aws_eks_access_entry" "admin_eks_access_entry" {
  cluster_name  = module.eks.cluster_name
  principal_arn = data.aws_iam_user.admin.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "eks_admin_policy" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_eks_access_entry.admin_eks_access_entry.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_access_policy_association" "eks_cluster_admin_policy" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_eks_access_entry.admin_eks_access_entry.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope {
    type = "cluster"
  }
}

resource "aws_security_group_rule" "allow_prometheus_lb" {
  type              = "ingress"
  from_port         = 9090
  to_port           = 9090
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # For production, restrict to your IP
  security_group_id = module.eks.node_security_group_id
  description       = "Allow Prometheus dashboard access"
}

resource "aws_security_group_rule" "allow_app_lb_8000" {
  type              = "ingress"
  from_port         = 8000
  to_port           = 8000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # For production, restrict to your IP
  security_group_id = module.eks.node_security_group_id
  description       = "Allow app access on port 8000"
}

  ########################
  # Cluster Autoscaler IRSA
  ########################

  # AWS account ID (used to build OIDC provider ARN when needed)
  data "aws_caller_identity" "current" {}

  # Issuer without https:// prefix for trust policy keys
  locals {
    cluster_oidc_issuer_without_scheme = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  }

  # IAM policy for Cluster Autoscaler
  resource "aws_iam_policy" "cluster_autoscaler" {
    name        = "ClusterAutoscalerPolicy-${var.cluster_name}"
    description = "Permissions for Kubernetes Cluster Autoscaler"
    policy      = jsonencode({
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

  output "cluster_autoscaler_role_arn" {
    description = "IAM role ARN for Cluster Autoscaler IRSA (annotate the SA with this)"
    value       = aws_iam_role.cluster_autoscaler_irsa.arn
  }
