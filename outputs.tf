output "public" {
  value = nonsensitive(jsondecode(jsonencode(module.public)))
}
output "main-org" {
  value = aws_organizations_organization.org
}
