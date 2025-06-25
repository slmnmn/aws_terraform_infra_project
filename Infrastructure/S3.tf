resource "aws_s3_bucket" "upload_bucket" { #REcuerde referenciar el otro bucket PARA LA OTRA APIGATEWAY
  bucket = var.bucket_name_upload
  force_destroy = true    #This is only for demonstration this SHOULD NOT be here
  tags = {
    Terraform = "true"
    Project   = "APIGatewayS3"
  }
}

resource "aws_s3_bucket_versioning" "upload_bucket_versioning" {
  bucket = aws_s3_bucket.upload_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}


resource "aws_s3_bucket" "static_bucket" { 
  bucket = var.bucket_name_static_website
  force_destroy = true    #This is only for demonstration this SHOULD NOT be here
  tags = {
    Terraform = "true"
    Project   = "APIGatewayS3"
  }
}

resource "aws_s3_bucket_public_access_block" "static_bucket_access" {
  bucket = aws_s3_bucket.static_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_versioning" "static_bucket_versioning" {
  bucket = aws_s3_bucket.static_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_website_configuration" "static_bucket_website_configuration" {
  bucket = aws_s3_bucket.static_bucket.id
  index_document {
    suffix = "index.html"
  }
}


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
  depends_on = [aws_s3_bucket_public_access_block.static_bucket_access] #Important because we need to create first everything before this.
}

# Para añadir la politica del bucket (Dado que es añadirle, mas no crearla)
