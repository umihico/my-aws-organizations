locals {
  env          = yamldecode(file("env.yml"))
  backend_path = "terraform-states-${get_aws_account_id()}-organizations"
  accounts     = jsondecode(run_cmd("aws", "organizations", "list-accounts", "--query", "Accounts"))
  providers = join("\n\n", [for account in local.accounts : <<PROVIDER
provider "aws" {
  region  = "ap-northeast-1"
  alias   = "${replace(account.Name, ".", "")}"
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
    region               = "ap-northeast-1"
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
  region  = "ap-northeast-1"
}

${local.providers}
EOF
}
