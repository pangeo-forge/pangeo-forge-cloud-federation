# Allow roles to assume permissions with their OIDC credentials,
# for use with IRSA
data "aws_iam_policy_document" "assume_role_with_oidc" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.cluster_oidc.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]
  }
}

# Setup the EBS CSI Driver addon - https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html
# Required for EBS volumes to be provisioned and attached
resource "aws_iam_role" "ebs_provisioner" {
  name               = "${var.cluster_name}-eks-ebs-provisioner"
  assume_role_policy = data.aws_iam_policy_document.assume_role_with_oidc.json
  permissions_boundary = var.permissions_boundary
}

resource "aws_iam_role_policy_attachment" "ebs_provisioner" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_provisioner.name
}

resource "aws_eks_addon" "ebs_provisioner" {
  cluster_name                = aws_eks_cluster.cluster.name
  addon_name                  = "aws-ebs-csi-driver"
  # Fetched version for current version from
  # eksctl utils describe-addon-versions --kubernetes-version <kubernetes-version>
  addon_version               = "v1.20.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  service_account_role_arn  = aws_iam_role.ebs_provisioner.arn
  depends_on = [
    aws_iam_role_policy_attachment.ebs_provisioner
  ]
}
