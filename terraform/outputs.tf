output "bucket_name" {
  value = aws_s3_bucket.bucket.id
}

output "queue_url" {
  value = aws_sqs_queue.queue.id
}

output "user_secret_key" {
  value     = aws_iam_access_key.access_key.secret
  sensitive = true
}

output "user_access_key" {
  value = aws_iam_access_key.access_key.id
}
