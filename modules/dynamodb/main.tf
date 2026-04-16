resource "aws_dynamodb_table" "this" {
  name         = "${var.name}-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Project = var.name
    Module  = "dynamodb"
  }
}