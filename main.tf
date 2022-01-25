locals {
  env = yamldecode(file("env.yml"))
}

resource "aws_organizations_organization" "org" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com"
  ]
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY"
  ]
  feature_set = "ALL"
}

resource "aws_kms_key" "master-key" {
  description         = "${local.env.name}-master-key"
  enable_key_rotation = true
  is_enabled          = true
}

resource "aws_kms_alias" "master-key-alias" {
  name          = "alias/${local.env.name}"
  target_key_id = aws_kms_key.master-key.key_id
}

module "public" {
  source = "./accounts"
  providers = {
    aws          = aws,
    aws.circleci = aws.circleci,
  }
}
