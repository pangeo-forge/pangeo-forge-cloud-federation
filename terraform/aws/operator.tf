resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = var.cert_manager_version

  set {
    # We can manage CRDs from inside Helm itself, no need for a separate kubectl apply
    name  = "installCRDs"
    value = true
  }
  wait = true
  depends_on = [
    aws_eks_cluster.cluster
  ]
}

resource "helm_release" "flink_operator" {
  name       = "flink-operator"
  repository = "https://downloads.apache.org/flink/flink-kubernetes-operator-${var.flink_operator_version}"
  chart      = "flink-kubernetes-operator"
  version    = var.flink_operator_version
  wait       = true
  values = [templatefile("${path.module}/flink-operator-helm-values.yaml.tftpl",
    {
      flink_version        = var.flink_version,
      flink_image_registry = var.flink_image_registry
    }
  )]

  depends_on = [
    # cert-manager is required by flink-operator, as there is a webhook to be validated -
    # and that requires HTTPS! Note that it doesn't require letsencrypt, just cert-manager.
    helm_release.cert_manager,
  ]
}
