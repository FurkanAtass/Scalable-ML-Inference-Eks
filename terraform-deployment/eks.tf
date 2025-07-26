module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.37.2"

  cluster_name    = var.cluster_name
  cluster_version = "1.33"

  # Optional
  cluster_endpoint_public_access = true

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

      min_size     = 1
      max_size     = 3
      desired_size = 1
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

data "aws_iam_user" "admin" {
  user_name = "Admin"
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