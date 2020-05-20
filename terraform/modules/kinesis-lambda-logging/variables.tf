variable "stream-name" {
  type = string
}

variable "bucket-name" {
  type = string
}

variable "stream-shard-count" {
  type = number
}

variable "lambda-endpoint" {
  type = string
  default = ""
}

variable "lambda-configurations" {
  type = object({
    fn_name = string
    batch_size = number
    starting_position = string
    handler = string
    file = string
    runtime = string
    source_code_hash = string
  })
}


