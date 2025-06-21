resource "aws_dynamodb_table" "lambda_data_table" {
  name           = var.dynamo_name
  billing_mode   = "PAY_PER_REQUEST" # Our traffic is pretty low
  hash_key       = "id"
  range_key      = "placa"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "placa"
    type = "S"
  }

  tags = {
    Terraform = "true"
    Project   = "APIGatewayS3"
  }
}