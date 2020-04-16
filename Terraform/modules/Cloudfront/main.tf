resource "aws_s3_bucket" "s3" {
  bucket = "${var.s3_bucket}"
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
    }
}

resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  bucket = "${aws_s3_bucket.s3.id}"

  policy = <<POLICY
{
  "Version": "2008-10-17",
  "Id": "PolicyForCloudFrontPrivateContent",
  "Statement": [
      {
          "Sid": "1",
          "Effect": "Allow",
          "Principal": {
              "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.origin_access_identity.id}"
          },
          "Action": "s3:GetObject",
          "Resource": "${aws_s3_bucket.s3.arn}/*"
    }
  ]
}

POLICY
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid = "S3GetObjectForCloudFront"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::$${var.s3_id}$${origin_path}*"]
    principals {
      type        = "AWS"
      identifiers = ["$${cloudfront_origin_access_identity_iam_arn}"]
    }
  }
  statement {
    sid = "S3ListBucketForCloudFront"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::$${var.s3_id}"]
    principals {
      type        = "AWS"
      identifiers = ["$${cloudfront_origin_access_identity_iam_arn}"]
    }
  }
}
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "${var.project}-${var.env}"
}

locals {
  s3_origin_id = "${aws_s3_bucket.s3.id}.s3.amazonaws.com"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.s3.bucket_regional_domain_name}"
    origin_id   = "${local.s3_origin_id}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path}"

    }
  }
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.s3_origin_id}"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

    restrictions {
        geo_restriction {
          restriction_type = "none"
        }
    }


  custom_error_response {
      error_code            = "404"
      response_code         = "200"
      response_page_path    = "/index.html"
    }
  custom_error_response {
      error_code            = "403"
      response_code         = "200"
      response_page_path    = "/index.html"
    }

  price_class = "PriceClass_200"
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
