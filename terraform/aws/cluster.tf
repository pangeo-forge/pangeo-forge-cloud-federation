
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cluster_control_plane" {
  name                 = "${var.cluster_name}-eks-cluster-control-plane"
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
  permissions_boundary = var.permissions_boundary
}

resource "aws_iam_role_policy_attachment" "cluster_controle_plane" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_control_plane.name
}

# Setup a cluster in the default VPC with default subnets
resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster_control_plane.arn

  vpc_config {
    subnet_ids = data.aws_subnets.default.ids
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_controle_plane
  ]
}

# Parse the OIDC issuer TLS certificate so we can setup IRSA correctly
data "tls_certificate" "cluster_oidc_certificate" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster_oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = data.tls_certificate.cluster_oidc_certificate.certificates[*].sha1_fingerprint
  url             = data.tls_certificate.cluster_oidc_certificate.url
}


module "cluster_autoscaler_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${var.cluster_name}_cluster_autoscaler"
  role_permissions_boundary_arn = var.permissions_boundary


  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_ids = [
    aws_eks_cluster.cluster.id
  ]

  oidc_providers = {
    main = {
      provider_arn = aws_iam_openid_connect_provider.cluster_oidc.arn
      # FIXME: We can't depend on release name + ns of cluster-autoscaler helm_release, because it
      # creates a circular dependency (lol).
      namespace_service_accounts = ["cluster-autoscaler:cluster-autoscaler-aws-cluster-autoscaler"]
    }
  }
}
