resource "aws_kinesis_stream" "this" {
  name = var.stream-name
  shard_count = var.stream-shard-count
}