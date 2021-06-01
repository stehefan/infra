resource "aws_s3_bucket" "bucket_tf_state" {
  bucket = "${local.account_id}-tf-state"
  acl = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {

    rule {
      bucket_key_enabled = true

      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
      }
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
