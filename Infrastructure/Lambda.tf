# Problema: si o si nos pide que tengamos de alguna manera el codigo subido a nuestra lambda si o si (Usaremos el default).
data "archive_file" "placeholder_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/files/placeholder_lambda.zip"
}

resource "aws_lambda_function" "s3_event_handler" {
  function_name = "S3UploadEventHandler"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.lambda_data_table.id #Reference to my DynamoDBtable
    }
  }

  filename         = data.archive_file.placeholder_lambda.output_path
  source_code_hash = data.archive_file.placeholder_lambda.output_base64sha256

  #Changes to the file will not affect to the infrastructure everytime we do terraform apply. MAYBE we can just edit the file in lambda_function and create a .zip everytime as our pipeline for deployment...
  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
      last_modified,
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs_attach,
    aws_iam_role_policy_attachment.s3_read_attach,
    aws_iam_role_policy_attachment.dynamodb_attach
  ]
}

#IDK if I should put this inside the S3.tf or here so it will be here before anything else.
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_event_handler.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.upload_bucket.arn #Bucket.
}

#Same with this 
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.upload_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_event_handler.arn
    events              = ["s3:ObjectCreated:Put"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}