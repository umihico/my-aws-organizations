terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_iam_user" "users" {
  for_each = toset(var.users)
  name     = each.value
}

