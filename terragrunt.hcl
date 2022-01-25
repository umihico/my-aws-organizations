locals {
  env          = yamldecode(file("env.yml"))
  backend_path = "terraform-backend-${run_cmd("aws", "sts", "get-caller-identity", "--profile", "${local.env.profile}", "--query", "Account", "--output", "text")}-${local.env.name}"
  accounts     = jsondecode(run_cmd("aws", "organizations", "list-accounts", "--profile", "${local.env.profile}", "--query", "Accounts"))
  providers = join("\n\n", [for account in local.accounts : <<PROVIDER
provider "aws" {
  alias   = "${replace(account.Name, ".", "")}"
  profile = "${local.env.profile}"
  region  = "${local.env.region}"
  assume_role {
    role_arn = "arn:aws:iam::${account.Id}:role/OrganizationAccountAccessRole"
  }
}
PROVIDER
  ])
}
remote_state {
  backend = "s3"
  generate = {
    path              = "remote_state_override.tf"
    if_exists         = "overwrite"
    disable_signature = true
  }
  config = {
    profile              = local.env.profile
    region               = local.env.region
    bucket               = local.backend_path
    key                  = "${path_relative_to_include()}/terraform.tfstate"
    encrypt              = true
    workspace_key_prefix = "workspaces"
    dynamodb_table       = local.backend_path
  }
}

generate "provider" {
  path              = "provider.tf"
  if_exists         = "overwrite"
  disable_signature = true
  contents          = <<EOF
provider "aws" {
  profile = "${local.env.profile}"
  region  = "${local.env.region}"
}

${local.providers}
EOF
}
