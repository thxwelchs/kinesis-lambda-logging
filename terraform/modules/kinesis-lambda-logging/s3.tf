resource "aws_s3_bucket" "this" {
  bucket = var.bucket-name
  force_destroy = true
}