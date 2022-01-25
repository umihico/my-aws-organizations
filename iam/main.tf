terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_iam_user" "users" {
  for_each = var.users
  name     = each.key
}

resource "aws_iam_user_policy_attachment" "users_custom_polices" {
  for_each   = var.users
  user       = aws_iam_user.users[each.key].name
  policy_arn = var.users[each.key]
}
