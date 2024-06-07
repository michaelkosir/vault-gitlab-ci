output "vault_addr" {
  value = "http://${aws_instance.vault.public_ip}:8200"
}

output "vault_token" {
  value = random_uuid.this.result
}

output "role_arn" {
  value = aws_iam_role.gitlab.arn
}
