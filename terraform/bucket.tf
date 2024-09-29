resource "aws_s3_bucket" "bucket" {
  bucket_prefix = var.bucket_prefix
  force_destroy = true
}

#resource "aws_s3_bucket_acl" "bucket_acl" {
#  bucket = aws_s3_bucket.bucket.id
#  acl    = "private"
#}

resource "aws_s3_bucket_policy" "allow_ses_access" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.allow_ses_access.json
}

data "aws_iam_policy_document" "allow_ses_access" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.bucket.arn,
      "${aws_s3_bucket.bucket.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:ses:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:receipt-rule-set/${aws_ses_receipt_rule_set.main.id}:receipt-rule/${var.ses_rule_name}"]
    }
  }
}
