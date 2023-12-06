provider "kubernetes" {
  host                   = aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_eks_cluster_auth" "cluster" {
  name = "${aws_eks_cluster.cluster.name}"
  depends_on = [
    aws_eks_cluster.cluster,
    helm_release.flink_operator
  ]
}

data "kubernetes_config_map" "operator_default" {
  # our `kind: Deployment` for historyserver
  # needs to use some of the ConfigMap keys/values
  # from the default operator config so
  # we handle that reuse here
  metadata {
    name = "flink-operator-config"
  }
  depends_on = [
    aws_eks_cluster.cluster,
    helm_release.flink_operator
  ]
}

locals {
  # removing lines that start with '#' b/c TF >> helm doesn't like them
  filtered_log4j_config = join("\n", [
    for line in split("\n", data.kubernetes_config_map.operator_default.data["log4j-console.properties"]) :
    line if !startswith(line, "#")
  ])

  # removing lines that start with '#' b/c TF >> helm doesn't like them
  filtered_flink_config = join("\n", [
  for line in split("\n", data.kubernetes_config_map.operator_default.data["flink-conf.yaml"]) :
  line if !startswith(line, "#")
  ])
}

resource "local_file" "log4j_config_output" {
  filename = "${path.module}/log4jconfig.yaml"
  content  = local.filtered_log4j_config
}

resource "local_file" "flink_config_output" {
  filename = "${path.module}/flinkconfig.yaml"
  content  = local.filtered_flink_config
}


resource "helm_release" "flink_historyserver" {
  name             = "flink-historyserver"
  chart            = "../../helm-charts/flink-historyserver"
  create_namespace = false

  set {
    name  = "efsFileSystemId"
    value = "${aws_efs_file_system.job_history.id}"
  }
  set {
    name  = "flinkVersion"
    value = "${var.flink_version}"
  }
  set {
    name  = "log4jConfig"
    value = local_file.log4j_config_output.content
  }
  set {
    name  = "flinkConfig"
    value = local_file.flink_config_output.content
  }
  wait = true
  depends_on = [
    aws_eks_cluster.cluster,
    helm_release.flink_operator
  ]
}
