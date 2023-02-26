/*
STEP 1. Encrypt email

PAGER="" aws kms encrypt \
 --key-id alias/my-aws-organizations \
 --plaintext "$(echo -n 'umihico@example.com' | base64)" \
 --output text \
 --query CiphertextBlob

STEP 2. Add account name and encrypted value into locals and run terraform apply

STEP 3. Check your email and set MFA to your root account

STEP 4. Add iam module and run terraform apply if you need iam users

STEP 5. aws iam create-access-key --user-name Bob --profile BobAccount
*/

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.public-circleci]
    }
  }
}

locals {
  users_custom_polices = {
    "public-circleci" = "AQICAHhknPcMN2mPQjlgkKH9EhrUk79o+4j1nUtJMmNPXkAKWgH6VYGA6RnFPGPTDGmh+fc2AAAAijCBhwYJKoZIhvcNAQcGoHoweAIBADBzBgkqhkiG9w0BBwEwHgYJYIZIAWUDBAEuMBEEDE8Rf7N7U9JRkTnjuAIBEIBG2DB2dofvmEaBgu855mF3yqPt8X+Nd/3IQb3BMFHPS6wtl1tuT92t+2xiWMln1eI71qhGnm3F1+vnsXeWIbbwEgLUU81JtA=="
  }

  # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-modifying-external-accounts.html
  shared_kms_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "AllowUseOfKeyInAccount${data.aws_caller_identity.self.account_id}",
          "Effect" : "Allow",
          "Action" : [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ],
          "Resource" : "${data.aws_kms_key.shared_key.arn}",
        }
      ]
  })
}

data "aws_caller_identity" "self" {}

data "aws_kms_key" "shared_key" {
  key_id = "alias/shared-key"
}

data "aws_kms_secrets" "users_custom_polices" {
  dynamic "secret" {
    for_each = local.users_custom_polices
    content {
      name    = secret.key
      payload = secret.value
    }
  }
}

resource "aws_organizations_account" "accounts" {
  for_each = var.vars.emails
  name     = each.key
  email    = each.value
}

module "circleci" {
  source    = "../iam"
  providers = { aws = aws.public-circleci }
  users = {
    "public-circleci" = data.aws_kms_secrets.users_custom_polices.plaintext["public-circleci"]
  }
}

module "circleci-shared-kms" {
  source            = "../iam/shared-kms"
  providers         = { aws = aws.public-circleci }
  users             = ["public-circleci"]
  shared_kms_policy = local.shared_kms_policy
  depends_on = [
    module.circleci
  ]
}
