resource "aws_s3_bucket" "bucket_tf_state" {
  bucket = "${local.account_id}-tf-state"
}

resource "aws_s3_bucket_acl" "bucket_tf_state_acl" {
  bucket = aws_s3_bucket.bucket_tf_state.bucket
  acl = "private"
}

resource "aws_s3_bucket_versioning" "bucket_tf_state_versioning" {
  bucket = aws_s3_bucket.bucket_tf_state.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_tf_state_encryption" {
  bucket = aws_s3_bucket.bucket_tf_state.bucket

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_dynamodb_table" "table_tf_state_lock" {
  hash_key = "LockID"
  name = "${local.account_id}-tf-state"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }
}
