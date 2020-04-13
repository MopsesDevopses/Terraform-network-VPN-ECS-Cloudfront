provider "aws" {
  region = "${var.region}"
}

resource "aws_s3_bucket" "s3" {
  bucket = "${var.tf_state_bucket}"
  acl    = "private"
}
