resource "aws_s3_bucket" "flink_store" {
  bucket = "${var.cluster_name}-flink-store"
}

resource "aws_s3_bucket" "buckets" {
  for_each = toset(var.buckets)
  bucket   = each.key

}
