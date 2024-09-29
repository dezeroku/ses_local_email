resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket      = aws_s3_bucket.bucket.id
  eventbridge = true
}

resource "aws_cloudwatch_event_rule" "capture_bucket_writes" {
  name_prefix = var.cloudwatch_rule_prefix
  description = "Capture writes to ses_local_email S3 bucket"

  event_pattern = jsonencode({
    source = ["aws.s3"],

    detail-type = [
      "Object Created"
    ],
    "detail" : {
      "bucket" : {
        "name" : [aws_s3_bucket.bucket.id]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "sqs" {
  rule = aws_cloudwatch_event_rule.capture_bucket_writes.name
  arn  = aws_sqs_queue.queue.arn
  sqs_target {
    message_group_id = "ses-local-email"
  }
}

resource "aws_sqs_queue" "queue" {
  name_prefix                 = var.queue_prefix
  fifo_queue                  = true
  content_based_deduplication = true
}

resource "aws_sqs_queue_policy" "policy" {
  queue_url = aws_sqs_queue.queue.id
  policy    = data.aws_iam_policy_document.sqs_queue_policy.json
}

data "aws_iam_policy_document" "sqs_queue_policy" {
  statement {
    effect  = "Allow"
    actions = ["SQS:SendMessage"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sqs_queue.queue.arn]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudwatch_event_rule.capture_bucket_writes.arn]
    }
  }
}
