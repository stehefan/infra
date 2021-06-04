resource "aws_s3_bucket" "website_buckets" {
  for_each = toset(local.website_urls)
  bucket = each.key
  acl = "public-read"

  website {
    index_document = "index.html"
  }
}

