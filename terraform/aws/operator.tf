
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = var.cert_manager_version

  set {
    name  = "installCRDs"
    value = true
  }
  wait = true
  depends_on = [
    helm_release.cert_manager,
    module.eks
  ]
}

resource "helm_release" "flink_operator" {
  name       = "flink-operator"
  repository = "https://downloads.apache.org/flink/flink-kubernetes-operator-${var.flink_operator_version}"
  chart      = "flink-kubernetes-operator"
  version    = var.flink_operator_version
  wait       = true

  depends_on = [
    helm_release.cert_manager,
  ]
}
