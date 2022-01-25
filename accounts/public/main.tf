/*
STEP 1. Encrypt email

PAGER="" aws kms encrypt \
 --key-id alias/my-aws-organizations \
 --plaintext "$(echo -n 'umihico@example.com' | base64)" \
 --output text \
 --query CiphertextBlob

STEP 2. Add account name and encrypted value into locals and run terraform apply

STEP 3. Check your email

STEP 4. Add iam module and run terraform apply if you need iam users
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
    "circleci" : "AQICAHjyt8yghuRp22llYfGQPF7gNyThuvomrTWRxYFkYvNYTAEXpluDPRHcqv0aLxa51BO3AAAAdzB1BgkqhkiG9w0BBwagaDBmAgEAMGEGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMcAiszaP9pndCZRGIAgEQgDTDy2k7/juQE0nufVzKRCupM902EVM9br1Uj4nIF25vt8WEw1cMWeA81AZIF1YR3ZDXYMwa"
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

resource "aws_organizations_account" "accounts" {
  for_each = local.emails
  name     = each.key
  email    = data.aws_kms_secrets.emails.plaintext[each.key]
}

module "circleci" {
  source    = "../../iam"
  providers = { aws = aws.circleci }
  users     = ["circleci-projects"]
}
