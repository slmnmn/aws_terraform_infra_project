# API Gateway REST API
resource "aws_api_gateway_rest_api" "s3_upload_api" {
  name        = var.api_name
  description = "An API Gateway to upload files to an S3 bucket"
}

# API Gateway Resource for {bucket}
resource "aws_api_gateway_resource" "bucket_resource" {
  rest_api_id = aws_api_gateway_rest_api.s3_upload_api.id
  parent_id   = aws_api_gateway_rest_api.s3_upload_api.root_resource_id
  path_part   = "{bucket}"
}

# API Gateway Resource for {filename}
resource "aws_api_gateway_resource" "filename_resource" {
  rest_api_id = aws_api_gateway_rest_api.s3_upload_api.id
  parent_id   = aws_api_gateway_resource.bucket_resource.id
  path_part   = "{filename}"
}

# --- PUT Method Configuration

# API Gateway Method for PUT
resource "aws_api_gateway_method" "put_object_method" {
  rest_api_id   = aws_api_gateway_rest_api.s3_upload_api.id
  resource_id   = aws_api_gateway_resource.filename_resource.id
  http_method   = "PUT"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.bucket"   = true
    "method.request.path.filename" = true
  }
}

# API Gateway Integration  PUT
resource "aws_api_gateway_integration" "s3_integration" {
  rest_api_id             = aws_api_gateway_rest_api.s3_upload_api.id
  resource_id             = aws_api_gateway_resource.filename_resource.id
  http_method             = aws_api_gateway_method.put_object_method.http_method
  integration_http_method = "PUT"
  type                    = "AWS"
  credentials             = aws_iam_role.api_gateway_execution_role.arn
  uri                     = "arn:aws:apigateway:${var.aws_region}:s3:path/{bucket}/{filename}"

  request_parameters = {
    "integration.request.path.bucket"   = "method.request.path.bucket"
    "integration.request.path.filename" = "method.request.path.filename"
  }
}

# --- CORS Configuration

# CORS: OPTIONS Method
resource "aws_api_gateway_method" "options_method" {
  rest_api_id   = aws_api_gateway_rest_api.s3_upload_api.id
  resource_id   = aws_api_gateway_resource.filename_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# CORS: OPTIONS Method Integration (MOCK)
resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.s3_upload_api.id
  resource_id = aws_api_gateway_resource.filename_resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# CORS: OPTIONS Method Response
resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.s3_upload_api.id
  resource_id = aws_api_gateway_resource.filename_resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# CORS: OPTIONS Integration Response
resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.s3_upload_api.id
  resource_id = aws_api_gateway_resource.filename_resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'PUT,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# CORS: Headers to the put response
resource "aws_api_gateway_method_response" "put_200" {
  rest_api_id = aws_api_gateway_rest_api.s3_upload_api.id
  resource_id = aws_api_gateway_resource.filename_resource.id
  http_method = aws_api_gateway_method.put_object_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "put_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.s3_upload_api.id
  resource_id = aws_api_gateway_resource.filename_resource.id
  http_method = aws_api_gateway_method.put_object_method.http_method
  status_code = aws_api_gateway_method_response.put_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

# --- Deployment and Stage (sorta)

# API Gateway Deployment
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.s3_upload_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.bucket_resource.id,
      aws_api_gateway_resource.filename_resource.id,
      aws_api_gateway_method.put_object_method.id,
      aws_api_gateway_integration.s3_integration.id,
      aws_api_gateway_method.options_method.id,
      aws_api_gateway_integration.options_integration.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.s3_upload_api.id
  stage_name    = "prod"
}
