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

variable "aws_tags" {
  type        = map(string)
  default     = {}
  description = <<-EOT
  (Optional) AWS resource tags.
  EOT
}

variable "permissions_boundary" {
  type        = string
  default     = null
  description = <<-EOT
  (Optional) ARN of the policy that is used to set the permissions boundary for
  the role.
  EOT
}

variable "aws_vpc" {
  type = map(string)
  default = {
    default = true
    id = null
  }
  description = <<-EOT
  (Optional) AWS VPC configuration.
  EOT
}

variable "node_groups" {
  description = "Flink node groups."
  type        = map(any)

  default = {
    jobmanager = {
      node_group_name = "flink-jobmanager"
      max_instances = 10
      instance_types = ["t3.large"]
      capacity_type = "ON_DEMAND"
    },
    taskmanager = {
      node_group_name = "flink-taskmanager"
      max_instances = 10
      instance_types = ["t3.large"]
      capacity_type = "SPOT"
    }
  }
}

variable "flink_operator_version" {
  default     = "1.5.0"
  description = <<-EOT
  Version of Flink Operator to install.
  EOT
}

variable "cluster_autoscaler_version" {
  default     = "9.21.0"
  description = <<-EOT
  Version of cluster autoscaler helm chart to install.
  EOT
}

variable "cert_manager_version" {
  default     = "1.9.1"
  description = <<-EOT
  Version of cert-manager helm chart to install.
  EOT
}

variable "nginx_ingress_version" {
  default     = "4.2.5"
  description = <<-EOT
  Version of the prometheus helm chart to install
  EOT
}

variable "prometheus_version" {
  default     = "15.12.0"
  description = <<-EOT
  Version of the prometheus helm chart to install
  EOT
}
variable "prometheus_disk_size" {
  default     = "16Gi"
  description = <<-EOT
  Amount of space to allocate to the disk storing prometheus metrics.
  EOT
}

variable "prometheus_metrics_retention_days" {
  default     = 180
  type        = number
  description = <<-EOT
  Number of days to retain all prometheus metrics for
  EOT
}

variable "prometheus_hostname" {
  default     = ""
  description = <<-EOT
  The DNS host at which the prometheus server should be reachable.

  Is just passed along to prometheus.server.ingress.hosts.
  EOT
}

variable "buckets" {
  default     = []
  description = <<-EOT
  List of S3 Buckets to create.
  EOT
}
