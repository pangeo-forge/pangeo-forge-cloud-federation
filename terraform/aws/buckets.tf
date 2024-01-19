resource "aws_s3_bucket" "flink_store" {
  bucket = "${var.cluster_name}-flink-store"
  force_destroy = true
}

resource "aws_s3_bucket" "buckets" {
  for_each = toset(var.buckets)
  bucket   = each.key

}
