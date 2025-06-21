#AssumeRole for api gateway and policy creation for apigateway to PUT 

resource "aws_iam_role" "api_gateway_execution_role" {
  name = "api-gateway-s3-put-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Terraform = "true"
    Project   = "APIGatewayS3"
  }
}

resource "aws_iam_policy" "s3_put_object_policy" {
  name        = "api-gateway-s3-put-object-policy"
  description = "Allows API Gateway to put objects into the S3 bucket."

  # Dynamic reference.
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "S3PutObject",
        Effect   = "Allow",
        Action   = "s3:PutObject",
        Resource = "${aws_s3_bucket.upload_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_put_attachment" {
  role       = aws_iam_role.api_gateway_execution_role.name
  policy_arn = aws_iam_policy.s3_put_object_policy.arn
}

#S3 BUCKET POLICY (we use data source since we are not creating a policy just kinda like attaching)

data "aws_iam_policy_document" "s3_static_website_policy_access" {
  statement {
    sid       = "PublicReadGetObject"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static_bucket.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "s3_static_website_policy_access" {
  bucket = aws_s3_bucket.static_bucket.id
  policy = data.aws_iam_policy_document.s3_static_website_policy_access.json #Reminder to put .json as policy attachign
}

#Lambda role and policies (The policies AWS bring us, are costumer managed (microservices DYNAMO) so we need to create it )

resource "aws_iam_role" "lambda_exec_role" {
  name = "s3_upload_processor_lambda_role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

#Not necessary but to have access to console logs inside the Lambda ok
resource "aws_iam_policy" "lambda_logging_policy" { 
  name        = "s3_processor_lambda_logging_policy"
  description = "Allows Lambda function to write logs to CloudWatch"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}

resource "aws_iam_policy" "s3_read_only_policy" {
  name        = "s3_upload_bucket_read_only_policy"
  description = "Allows Lambda to read objects from the S3 upload bucket"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ],
        Effect = "Allow",
        Resource = "${aws_s3_bucket.upload_bucket.arn}/*" #
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_read_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.s3_read_only_policy.arn
}


resource "aws_iam_policy" "dynamodb_read_write_policy" {
  name        = "lambda_dynamodb_read_write_policy"
  description = "Allows Lambda to read from and write to the DynamoDB table"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ],
        Effect = "Allow",
        Resource = aws_dynamodb_table.lambda_data_table.arn
      }
    ]
  })
}