provider "aws" {
  access_key                  = "mock_access_key"
  region                      = "us-east-1"
  s3_force_path_style         = true
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    cloudwatch     = var.LOCALSTACK_ENDPOINT
    firehose       = var.LOCALSTACK_ENDPOINT
    iam            = var.LOCALSTACK_ENDPOINT
    kinesis        = var.LOCALSTACK_ENDPOINT
    lambda         = var.LOCALSTACK_ENDPOINT
    s3             = var.LOCALSTACK_ENDPOINT
    sqs            = var.LOCALSTACK_ENDPOINT
    ssm            = var.LOCALSTACK_ENDPOINT
    sts            = var.LOCALSTACK_ENDPOINT
  }
}

