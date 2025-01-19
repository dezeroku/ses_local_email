locals {
  lambda_entry_checker_src_dir     = var.lambda_entry_checker_src_dir != "" ? var.lambda_entry_checker_src_dir : "${path.module}/../lambda/entry_checker"
  lambda_entry_checker_payload_dir = var.lambda_entry_checker_payload_dir != "" ? var.lambda_entry_checker_payload_dir : "${path.module}/../lambda/entry_checker/payload"
}
