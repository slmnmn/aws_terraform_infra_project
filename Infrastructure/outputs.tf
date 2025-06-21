output "invoke_url" {
  description = "The invocation URL for the API stage. Use this URL with the path '/{bucket-name}/{filename}'."
  value       = "${aws_api_gateway_stage.api_stage.invoke_url}/${aws_s3_bucket.upload_bucket.id}/"
}

output "S3_static" {
    description = "Static bucket name"
    value = aws_s3_bucket.static_bucket.id
}

output "S3_upload_bucket"{
    description = "upload bucket name, use it to change your put link"
    value = "${aws_s3_bucket.upload_bucket.id}"
}