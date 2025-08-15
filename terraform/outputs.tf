output "iam_user_name" {
  value = aws_iam_user.vault_kms.name
}

output "policy_arn" {
  value = aws_iam_policy.vault_kms.arn
}

output "access_key_id" {
  value       = aws_iam_access_key.this.id
  sensitive   = true
}

output "secret_access_key" {
  value       = aws_iam_access_key.this.secret
  sensitive   = true
}