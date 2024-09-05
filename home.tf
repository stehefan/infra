resource "aws_route53_zone" "website_zones" {
  for_each = toset(local.website_urls)
  name = each.key
}

resource "aws_route53_record" "website_records" {
  for_each = toset(local.website_urls)
  zone_id = aws_route53_zone.website_zones[each.key].zone_id
  name = each.key
  type = "A"

  alias {
    name = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "website_www_records" {
  for_each = toset(local.website_urls)
  zone_id = aws_route53_zone.website_zones[each.key].zone_id
  name = "www.${each.key}"
  type = "CNAME"
  ttl = 60
  records = [
    each.key]
}

resource "aws_route53_record" "validation_records" {
  for_each = {
  for dvo in aws_acm_certificate.website_certificate.domain_validation_options : dvo.domain_name => {
    name = dvo.resource_record_name
    record = dvo.resource_record_value
    type = dvo.resource_record_type
    zone_id = dvo.domain_name == "stehefan.de" ? aws_route53_zone.website_zones["stehefan.de"].zone_id : aws_route53_zone.website_zones["stefanlier.de"].zone_id
  }
  }

  allow_overwrite = true
  name = each.value.name
  records = [
    each.value.record]
  ttl = 60
  type = each.value.type
  zone_id = each.value.zone_id
}

resource "aws_s3_bucket" "website_bucket" {
  bucket = "${local.account_id}-home-website"
}

resource "aws_s3_bucket_acl" "website_bucket_acl" {
  bucket = aws_s3_bucket.website_bucket.bucket
  acl = "private"
}

resource "aws_cloudfront_origin_access_identity" "website_oai" {
  comment = "Origin Access Identity for Home"
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions = [
      "s3:GetObject"]
    resources = [
      "${aws_s3_bucket.website_bucket.arn}/*"]

    principals {
      type = "AWS"
      identifiers = [
        aws_cloudfront_origin_access_identity.website_oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "website_bucket_policy" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

resource "aws_acm_certificate" "website_certificate" {
  provider = aws.us-east-1

  domain_name = local.website_urls[0]
  subject_alternative_names = [
    local.website_urls[1],
    "*.${local.website_urls[0]}",
    "*.${local.website_urls[1]}",
  ]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "website_certificate_validation" {
  provider = aws.us-east-1

  certificate_arn = aws_acm_certificate.website_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.validation_records : record.fqdn]
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled = true
  is_ipv6_enabled = true
  comment = "Cloudfront distribution for ${join(" and ", local.website_urls)}"
  default_root_object = "index.html"
  aliases = concat(local.website_urls, formatlist("www.%s", local.website_urls))

  origin {
    domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.website_oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS"]
    cached_methods = [
      "GET",
      "HEAD"]
    target_origin_id = local.s3_origin_id
    compress = true
    viewer_protocol_policy = "redirect-to-https"
    min_ttl = 3600
    default_ttl = 86400
    max_ttl = 604800

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.redirect.arn
    }

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern = "*.htm*"

    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS"]
    cached_methods = [
      "GET",
      "HEAD"
    ]
    target_origin_id = local.s3_origin_id
    compress = true
    viewer_protocol_policy = "redirect-to-https"
    min_ttl = 0
    default_ttl = 60
    max_ttl = 60

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.redirect.arn
    }

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.website_certificate.arn
    ssl_support_method = "sni-only"
  }

  tags = {
    Target = "S3"
    Name = "HomeDistribution"
  }
}

resource "aws_cloudfront_function" "redirect" {
  name    = "redirect-stehefan-to-stefanlier"
  runtime = "cloudfront-js-2.0"
  comment = "Redirects stehefan.de to stefanlier.de"
  publish = true
  code    = file("${path.module}/functions/redirect.js")
}