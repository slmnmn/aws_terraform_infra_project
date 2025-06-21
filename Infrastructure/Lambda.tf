resource "aws_lambda_function" "s3_event_handler" {
  function_name = "S3UploadEventHandler"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.handler" # IMPORTANT: The handler name must match your future code.
  runtime       = "python3.11"
  timeout       = 30

# WITHOUT THIS LIFECYCLE, IF WE RUN APPLY AGAIN THE CODE WOULD BE DELETED. 
  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
      last_modified,
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs_attach,
    aws_iam_role_policy_attachment.s3_read_attach
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