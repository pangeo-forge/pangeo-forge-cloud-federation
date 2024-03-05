resource "aws_efs_file_system" "job_history" {
  count          = var.enable_flink_historyserver ? 1: 0
  creation_token = "${var.cluster_name}-flink-job-history"
}

resource "aws_efs_mount_target" "job_history" {
  for_each         = var.enable_flink_historyserver ? toset(data.aws_subnets.default.ids) : toset([])
  file_system_id   = aws_efs_file_system.job_history[0].id
  subnet_id        = each.value
  security_groups  = [aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id]
}
