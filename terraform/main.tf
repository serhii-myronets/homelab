data "aws_kms_key" "vault" {
  key_id = "alias/vault-unseal"
}


# data "aws_caller_identity" "me" {}
# locals { account = data.aws_caller_identity.me.account_id }

# resource "aws_kms_key" "vault" {
#   description             = "Vault auto-unseal KMS key"
#   deletion_window_in_days = 30
#   enable_key_rotation     = true
#
#
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Sid: "EnableRoot",
#         Effect: "Allow",
#         Principal: { AWS: "arn:aws:iam::${local.account}:root" },
#         Action: "kms:*",
#         Resource: "*"
#       },
#       {
#         Sid: "AllowIAMPolicies",
#         Effect: "Allow",
#         Principal: { AWS: "arn:aws:iam::${local.account}:root" },
#         Action: [
#           "kms:CreateGrant","kms:ListGrants","kms:RevokeGrant",
#           "kms:DescribeKey","kms:Encrypt","kms:Decrypt","kms:GenerateDataKey*"
#         ],
#         Resource: "*"
#       }
#     ]
#   })
#
#   lifecycle {
#     prevent_destroy = true    # запобіжник від випадкового destroy
#   }
#
#   tags = var.tags
# }


resource "aws_iam_user" "vault_kms" {
  name = var.name_prefix
  tags = var.tags
}

resource "aws_iam_policy" "vault_kms" {
  name        = "${var.name_prefix}-policy"
  description = "Minimal KMS perms for Vault auto-unseal"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid    = "VaultKMSUnsealMinimal",
      Effect = "Allow",
      Action = [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey"
      ],
      Resource = data.aws_kms_key.vault.arn
    }]
  })
}

resource "aws_iam_user_policy_attachment" "attach" {
  user       = aws_iam_user.vault_kms.name
  policy_arn = aws_iam_policy.vault_kms.arn
}

resource "aws_iam_access_key" "this" {
  user  = aws_iam_user.vault_kms.name
}