resource "aws_ses_receipt_rule_set" "main" {
  rule_set_name = var.ses_rule_set_name
}

resource "aws_ses_active_receipt_rule_set" "main" {
  rule_set_name = aws_ses_receipt_rule_set.main.id
}

resource "aws_ses_receipt_rule" "store" {
  depends_on = [
    aws_s3_bucket_policy.allow_ses_access,
    aws_lambda_permission.lambda_entry_checker_allow_ses
  ]
  name          = var.ses_rule_name
  rule_set_name = aws_ses_receipt_rule_set.main.id
  recipients    = var.recipients
  enabled       = true
  scan_enabled  = true

  lambda_action {
    function_arn    = aws_lambda_function.lambda_entry_checker.arn
    invocation_type = "RequestResponse"
    position        = 1
  }

  s3_action {
    bucket_name = aws_s3_bucket.bucket.id
    position    = 2
  }
}
