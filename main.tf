module "dynamodb" {
  source = "./modules/dynamodb"
  name   = "demo"
}

module "lambda" {
  source = "./modules/lambda"

  name                = "demo"
  lambda_zip          = "${path.module}/modules/lambda/lambda.zip"
  dynamodb_table_name = module.dynamodb.table_name
  role_arn = "arn:aws:iam::339712980459:role/LabRole"
  bucket_name = module.s3.bucket_name
}

module "api_gateway" {
  source = "./modules/api_gateway"

  name              = "demo"
  lambda_invoke_arn = module.lambda.invoke_arn
}

resource "aws_lambda_permission" "apigw" {
  statement_id = "AllowExecutionFromAPIGateway"
  action       = "lambda:InvokeFunction"

  function_name = module.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${module.api_gateway.execution_arn}/*/*"
}

module "s3" {
  source = "./modules/s3"
  name   = "demo"
}
