output "invoke_url" {
  description = "The invocation URL for the API stage. Use this URL with the path '/{bucket-name}/{filename}'."
  value       = "${aws_api_gateway_stage.api_stage.invoke_url}/${aws_s3_bucket.upload_bucket.id}/"
}

output "S3_static" {
    description = "Static bucket name"
    value = aws_s3_bucket.static_bucket.id
}

output "S3_upload_bucket"{
    description = "Upload bucket name, use it to change your put link"
    value = aws_s3_bucket.upload_bucket.id
}

output "s3_static_website_link" {
  description = "Show the static website link"
  value = "http://${aws_s3_bucket.static_bucket.id}.s3-website-us-east-1.amazonaws.com"
}