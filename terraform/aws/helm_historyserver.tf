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

  wait = true
  depends_on = [
    aws_eks_cluster.cluster,
    helm_release.flink_operator
  ]
}
