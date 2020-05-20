module "kinesis-lambda-logging" {
  source = "./modules/kinesis-lambda-logging"
  bucket-name = "my-bucket"
  stream-name = "web-log-stream"
  stream-shard-count = 1
  lambda-configurations = {
    fn_name = "stream-transformation"
    batch_size = 100
    starting_position = "LATEST"
    handler = "index.handler"
    file = data.archive_file.function.output_path
    source_code_hash = data.archive_file.function.output_base64sha256
    runtime = "nodejs12.x"
    endpoint = var.LOCALSTACK_ENDPOINT
  }

}

data "archive_file" "function" {
  type = "zip"
  source_dir = "../lambda/"
  output_path = "./function.zip"
  depends_on = ["null_resource.npm_install"]
}

resource "null_resource" "npm_install" {
  provisioner "local-exec" {
    command = "npm install"
    working_dir = "../lambda/"
  }
}
