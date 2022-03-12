terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_iam_user_policy" "shared_kms_policy" {
  for_each = toset(var.users)
  name     = "${each.key}-shared-kms-policy"
  user     = each.key
  policy   = var.shared_kms_policy
}
