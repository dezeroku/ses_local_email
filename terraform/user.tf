resource "aws_iam_user" "user" {
  name = var.user_name
}

resource "aws_iam_access_key" "access_key" {
  user = aws_iam_user.user.name
}

resource "aws_iam_user_policy" "iam" {
  user   = aws_iam_user.user.name
  policy = data.aws_iam_policy_document.user_policy.json
}

data "aws_iam_policy_document" "user_policy" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
    ]

    resources = [
      aws_s3_bucket.bucket.arn,
      "${aws_s3_bucket.bucket.arn}/*",
    ]
  }
  statement {
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:DeleteMessageBatch",
    ]

    resources = [
      aws_sqs_queue.queue.arn,
    ]
  }

}
