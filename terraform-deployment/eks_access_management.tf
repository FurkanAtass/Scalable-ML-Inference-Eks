########################
# EKS Access Management
########################

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