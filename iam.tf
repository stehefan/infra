resource "aws_iam_role" "role_deploy" {
  name = "deploy"
  description = "Role used to deploy infrastructure and applications"

  assume_role_policy = data.aws_iam_policy_document.policy_doc_assume_role_deploy.json
  managed_policy_arns = [
    aws_iam_policy.policy_deploy.arn
  ]
}

data "aws_iam_policy_document" "policy_doc_assume_role_deploy" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"]
    principals {
      identifiers = [
        "arn:aws:iam::${local.account_id}:root"]
      type = "AWS"
    }
  }
}

data "aws_iam_policy_document" "policy_doc_deploy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:*",
      "acm:*",
      "route53:*",
      "route53domains:*",
      "cloudfront:*",
      "iam:*",
      "dynamodb:*"
    ]
    resources = [
      "*"]
  }
}

resource "aws_iam_policy" "policy_deploy" {
  policy = data.aws_iam_policy_document.policy_doc_deploy.json
}

resource "aws_iam_user" "user_github" {
  name = "github"
}

resource "aws_iam_access_key" "user_github_access_key" {
  user = aws_iam_user.user_github.name
}

resource "aws_iam_user_policy" "policy_github_s3_deploy" {
  name = "s3-deploy-to-home-policy"
  user = aws_iam_user.user_github.name
  policy = data.aws_iam_policy_document.policy_doc_github_s3_deploy.json
}

data "aws_iam_policy_document" "policy_doc_github_s3_deploy" {
  statement {
    actions = [
      "s3:*"
    ]
    effect = "Allow"
    resources = [
      aws_s3_bucket.website_bucket.arn,
      "${aws_s3_bucket.website_bucket.arn}/*"
    ]
  }
}
