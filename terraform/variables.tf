variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}


variable "name_prefix" {
  type        = string
  default     = "vault-kms"
}

variable "tags" {
  type        = map(string)
  default     = {}
}