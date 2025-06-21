variable "api_name" {
  description = "The name for the API Gateway REST API."
  type        = string
  default     = "S3UploadAPI"
}

 # S3 variables

variable "bucket_name_upload" {
  description = "The name of the S3 bucket for uploads. Must be globally unique."
  type        = string
}

variable "bucket_name_static_website"{
  description = "The name of the static website bucket"
  type = string
}

variable "aws_region" {
  description = "The AWS region to deploy the resources in."
  type        = string
  default     = "us-east-1"
}


# USe the TF.vars for everything most importantly the name of the buckets (No default value)