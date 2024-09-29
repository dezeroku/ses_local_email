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

# REQUIRED
variable "recipients" {
  type        = list(string)
  description = "List of emails that will get processed"
}
