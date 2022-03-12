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

module "public" {
  source = "./accounts"
  providers = {
    aws          = aws,
    aws.circleci = aws.circleci,
  }
}
