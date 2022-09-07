variable "region" {
  type        = string
  description = <<-EOT
  AWS region to perform all our operations in.
  EOT
}

variable "cluster_name" {
  type        = string
  description = <<-EOT
  Name of EKS cluster to create
  EOT
}

variable "instance_type" {
  default     = "t3.large"
  description = <<-EOT
  AWS Instance type used for nodes.
  EOT
}

variable "max_instances" {
  default     = 10
  type        = number
  description = <<-EOT
  Maximum number of instances the autoscaler will scale the cluster up to.
  EOT
}

variable "flink_operator_version" {
  default     = "1.1.0"
  description = <<-EOT
  Version of Flink Operator to install.
  EOT
}

variable "buckets" {
  default     = []
  description = <<-EOT
  List of S3 Buckets to create.
  EOT
}
