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

  # Referencia de manera dinamica el ARN del bucket.
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
