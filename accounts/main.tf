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
      configuration_aliases = [aws.circleci]
    }
  }
}

locals {
  emails = {
    "circleci" : "AQICAHhknPcMN2mPQjlgkKH9EhrUk79o+4j1nUtJMmNPXkAKWgE3LEXiRrZy/kdrckItk1A0AAAAdjB0BgkqhkiG9w0BBwagZzBlAgEAMGAGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQM+XHQsA5fXLPJrJzHAgEQgDMfAIMhfO4ht/BWY1vetPcQTYz9sbdjvhkHcm6za1W/U3Bm7ZqBCk5Py5IFNIc6ZKQiaqc="
    "bastion" : "AQICAHhknPcMN2mPQjlgkKH9EhrUk79o+4j1nUtJMmNPXkAKWgE6lxBZqEiKT/GjBKxmE4f5AAAAdjB0BgkqhkiG9w0BBwagZzBlAgEAMGAGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMxhIpinBtC7+7S0QnAgEQgDOJhVdQWKACoq0KLLZVouTvVhxZnnOoaMXuHWsDkndwciVK7pCznh2cwGjn9Cd7pxVuIBA="
  }
  users_custom_polices = {
    "circleci-projects" = "AQICAHhknPcMN2mPQjlgkKH9EhrUk79o+4j1nUtJMmNPXkAKWgH6VYGA6RnFPGPTDGmh+fc2AAAAijCBhwYJKoZIhvcNAQcGoHoweAIBADBzBgkqhkiG9w0BBwEwHgYJYIZIAWUDBAEuMBEEDE8Rf7N7U9JRkTnjuAIBEIBG2DB2dofvmEaBgu855mF3yqPt8X+Nd/3IQb3BMFHPS6wtl1tuT92t+2xiWMln1eI71qhGnm3F1+vnsXeWIbbwEgLUU81JtA=="
  }
}

data "aws_kms_secrets" "emails" {
  dynamic "secret" {
    for_each = local.emails
    content {
      name    = secret.key
      payload = secret.value
    }
  }
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
  for_each = local.emails
  name     = each.key
  email    = data.aws_kms_secrets.emails.plaintext[each.key]
}

module "circleci" {
  source    = "../iam"
  providers = { aws = aws.circleci }
  users = {
    "circleci-projects" = data.aws_kms_secrets.users_custom_polices.plaintext["circleci-projects"]
  }
}
