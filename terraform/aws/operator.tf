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
  values = [file("${path.module}/flink-operator-helm-values.yaml")]

#  # Let's grab metrics from the operator and put it into prometheus
#  set {
#    name  = "operatorPod.annotations.prometheus\\.io/scrape"
#    value = "true"
#    # Terraform seems to type-coerce ugh
#    # Annotations *must* have string values, so we force these to be strings
#    type = "string"
#  }
#  set {
#    name  = "operatorPod.annotations.prometheus\\.io/port"
#    value = "9999"
#    type  = "string"
#  }
#
#  # Enable prometheus metrics for all
#  set {
#    name = "defaultConfiguration.flink-conf\\.yaml"
#    value = yamlencode({
#      "kubernetes.operator.metrics.reporter.prom.factory.class" : "org.apache.flink.metrics.prometheus.PrometheusReporterFactory",
#      "kubernetes.operator.metrics.reporter.prom.port" : "9999",
#      "kubernetes.jobmanager.annotations" : {
#        "prometheus.io/scrape" : "true",
#        "prometheus.io/port" : "9999"
#      },
#      "kubernetes.taskmanager.annotations" : {
#        "prometheus.io/scrape" : "true",
#        "prometheus.io/port" : "9999"
#      },
#      "jobmanager.archive.fs.dir": var.historyserver_mount_path,
#      "historyserver.archive.fs.dir": var.historyserver_mount_path,
#    })
#  }
#
#  set {
#    name  = "metrics.port"
#    value = "9999"
#  }

  depends_on = [
    # cert-manager is required by flink-operator, as there is a webhook to be validated -
    # and that requires HTTPS! Note that it doesn't require letsencrypt, just cert-manager.
    helm_release.cert_manager,
  ]
}
