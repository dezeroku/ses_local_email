variable "tags" {
  type = map(string)
  default = {
    Service = "ses-local-email"
  }
}

variable "ses_rule_set_name" {
  type    = string
  default = "ses-local-email"
}

variable "ses_rule_name" {
  // This is here to avoid race condition between rule and ACL
  type    = string
  default = "store"
}

variable "cloudwatch_rule_prefix" {
  type    = string
  default = "ses-local-email-"
}

variable "queue_prefix" {
  type    = string
  default = "ses-local-email-"
}

variable "bucket_prefix" {
  type    = string
  default = "ses-local-email-"
}

variable "user_name" {
  type    = string
  default = "ses-local-email"
}

variable "lambda_entry_checker_src_dir" {
  type        = string
  default     = ""
  description = "Override default src dir for lambda"
}

variable "lambda_entry_checker_payload_dir" {
  type        = string
  default     = ""
  description = "Override default payload dir for lambda"
}

variable "lambda_entry_checker_function_name" {
  type    = string
  default = "ses-local-email-entry-checker"
}

variable "lambda_entry_checker_iam_role_name" {
  type    = string
  default = "ses-local-email-entry-checker"
}

variable "senders_regex" {
  type        = string
  description = "Regex describing allowed sender emails"
  default     = ".*"
}

# REQUIRED
variable "recipients" {
  type        = list(string)
  description = "List of emails that will get processed"
}
