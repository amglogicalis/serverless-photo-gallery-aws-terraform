resource "aws_lambda_function" "this" {
  function_name = "${var.name}-lambda"
  runtime       = "python3.12"
  handler       = "lambda_function.lambda_handler"

  filename = var.lambda_zip
  source_code_hash = filebase64sha256(var.lambda_zip)

  role = var.role_arn

  timeout     = 3
  memory_size = 128

  environment {
    variables = {
      TABLE_NAME = var.dynamodb_table_name
      BUCKET_NAME = var.bucket_name
    }
  }
}