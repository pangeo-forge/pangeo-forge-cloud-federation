provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_id]
    }
  }
}

resource "helm_release" "autoscaler" {
  name             = "cluster-autoscaler"
  repository       = "https://kubernetes.github.io/autoscaler"
  chart            = "cluster-autoscaler"
  version          = var.cluster_autoscaler_version
  namespace        = "cluster-autoscaler"
  create_namespace = true

  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "awsRegion"
    value = var.region
  }

  set {
    # Double escaping needed as otherwise . is inteprerted as a nesting
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.cluster_autoscaler_irsa.iam_role_arn
  }

  wait = true
  depends_on = [
    module.eks
  ]
}

resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus"
  namespace        = "support"
  create_namespace = true
  version          = var.prometheus_version

  set {
    # We don't use alertmanager
    name  = "alertmanager.enabled"
    value = false
  }

  set {
    # We don't use pushgateway either
    name  = "pushgateway.enabled"
    value = false
  }

  set {
    name  = "server.persistentVolume.size"
    value = var.prometheus_disk_size
  }

  set {
    name  = "server.retention"
    value = "${var.prometheus_metrics_retention_days}d"
  }

  set {
    name  = "server.ingress.enabled"
    value = true
  }

  set {
    name  = "server.ingress.hosts[0]"
    value = var.prometheus_hostname
  }

  set {
    # Double \\ is neded so the entire last part of the name is used as key
    name  = "server.ingress.annotations.kubernetes\\.io/ingress\\.class"
    value = "nginx"
  }

  set {
    # We have a persistent disk attached, so the default (RollingUpdate)
    # can sometimes get 'stuck' and require pods to be manually deleted.
    name  = "strategy.typ"
    value = "Recreate"
  }
  wait = true
  depends_on = [
    module.eks
  ]
}

resource "helm_release" "ingress" {
  name             = "ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "support"
  create_namespace = true
  version          = var.nginx_ingress_version

  wait = true
  depends_on = [
    module.eks
  ]
}
