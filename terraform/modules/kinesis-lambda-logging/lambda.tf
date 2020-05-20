resource "aws_lambda_function" "this" {
  function_name = var.lambda-configurations.fn_name
  handler = var.lambda-configurations.handler
  role = aws_iam_role.lambda-ex.arn
  runtime = var.lambda-configurations.runtime
  filename = var.lambda-configurations.file
  source_code_hash = var.lambda-configurations.source_code_hash
  environment {
    variables = {
      LAMBDA_ENDPOINT = var.lambda-endpoint
      BUCKET_NAME = var.bucket-name
    }
  }
}

resource "aws_lambda_event_source_mapping" "this" {
  event_source_arn = aws_kinesis_stream.this.arn
  function_name = aws_lambda_function.this.function_name
  batch_size = var.lambda-configurations.batch_size
  starting_position = var.lambda-configurations.starting_position
}