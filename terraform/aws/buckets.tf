resource "aws_s3_bucket" "buckets" {
  for_each = toset(var.buckets)
  bucket   = each.key

}
