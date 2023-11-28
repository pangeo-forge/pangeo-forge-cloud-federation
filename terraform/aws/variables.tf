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

variable "instance_type" {
  default     = "t3.large"
  description = <<-EOT
  AWS Instance type used for nodes.
  EOT
}

variable "capacity_type" {
  default     = "ON_DEMAND"
  description = <<-EOT
  Whether to use ON_DEMAND or SPOT instances.
  EOT
  
  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "The capcity_type value must be ON_DEMAND or SPOT."
  }
}

variable "max_instances" {
  default     = 10
  type        = number
  description = <<-EOT
  Maximum number of instances the autoscaler will scale the cluster up to.
  EOT
}

variable "flink_operator_version" {
  default     = "1.6.1"
  description = <<-EOT
  Version of Flink Operator to install.
  EOT
}

variable "flink_version" {
  default     = "1.16"
  description = <<-EOT
  Version of Flink to install.
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

variable "historyserver_mount_path" {
  default     = "/opt/history/jobs"
  description = <<-EOT
  The mount path where Flink historyserver will archive jobs to so it can respond

  to REST requests about statuses after job managers are gone
  EOT
}
