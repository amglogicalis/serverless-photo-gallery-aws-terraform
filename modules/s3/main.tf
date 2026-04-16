resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "this" {
  bucket = "${var.name}-photo-${random_id.suffix.hex}"
}

resource "aws_s3_bucket_lifecycle_configuration" "photos_expire" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "delete-photos-after-7-days"
    status = "Enabled"

    expiration {
      days = 7
    }
  }
}