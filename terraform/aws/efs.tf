resource "aws_efs_file_system" "job_history" {
  creation_token = "pforge-flink-job-history"
}

resource "aws_efs_mount_target" "job_history" {
  for_each         = toset(data.aws_subnets.default.ids)
  file_system_id   = aws_efs_file_system.job_history.id
  subnet_id        = each.value
  security_groups  = [aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id]
}
