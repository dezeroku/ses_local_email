data "aws_iam_policy_document" "lambda_entry_checker_policy_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_entry_checker" {
  name               = var.lambda_entry_checker_iam_role_name
  assume_role_policy = data.aws_iam_policy_document.lambda_entry_checker_policy_assume_role.json
}

data "aws_iam_policy_document" "lambda_entry_checker_policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup"
    ]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.lambda_entry_checker_function_name}:*"]
  }

  statement {
    actions = [
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.lambda_entry_checker_function_name}:*:*"
    ]
  }
}

resource "aws_iam_policy" "lambda_entry_checker_policy" {
  name_prefix = "ses-local-email-lambda-entry-checker-"
  policy      = data.aws_iam_policy_document.lambda_entry_checker_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_entry_checker_policy" {
  role       = aws_iam_role.lambda_entry_checker.name
  policy_arn = aws_iam_policy.lambda_entry_checker_policy.arn
}

resource "aws_lambda_permission" "lambda_entry_checker_allow_ses" {
  statement_id   = "AllowExecutionFromSES"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.lambda_entry_checker.function_name
  principal      = "ses.amazonaws.com"
  source_account = data.aws_caller_identity.current.account_id
  source_arn     = "arn:aws:ses:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:receipt-rule-set/${aws_ses_receipt_rule_set.main.id}:receipt-rule/${var.ses_rule_name}"
}

data "archive_file" "lambda_entry_checker_payload" {
  type       = "zip"
  source_dir = local.lambda_entry_checker_src_dir
  excludes = [
    "venv",
    "_pycache_",
    "payload"
  ]
  output_path = "${local.lambda_entry_checker_payload_dir}/payload.zip"
}

resource "aws_lambda_function" "lambda_entry_checker" {
  filename         = data.archive_file.lambda_entry_checker_payload.output_path
  source_code_hash = data.archive_file.lambda_entry_checker_payload.output_base64sha256
  function_name    = var.lambda_entry_checker_function_name
  role             = aws_iam_role.lambda_entry_checker.arn
  handler          = "entry_checker/main.main"
  runtime          = "python3.12"
  environment {
    variables = {
      ALLOWED_SENDERS_REGEX = var.senders_regex
    }
  }
  # Same timeout as the default
  timeout    = 3
  depends_on = [aws_cloudwatch_log_group.lambda_entry_checker]
}

resource "aws_cloudwatch_log_group" "lambda_entry_checker" {
  name              = "/aws/lambda/${var.lambda_entry_checker_function_name}"
  retention_in_days = 14
}
