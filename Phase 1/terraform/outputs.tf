output "control_public_ip" {
  value = aws_instance.control.public_ip
}

output "github_actions_role_arn" {
  description = "IAM role assumed by GitHub Actions through OIDC"
  value       = aws_iam_role.github_actions.arn
}

output "managed_instance_ids" {
  description = "Managed EC2 instance IDs used for SSM deployments"
  value       = aws_instance.managed[*].id
}

output "github_oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.github_actions.arn
}

output "managed_public_ips" {
  value = aws_instance.managed[*].public_ip
}

output "managed_private_ips" {
  description = "Use these in ansible/inventory.ini"
  value       = aws_instance.managed[*].private_ip
}

output "ssh_config_snippet" {
  description = "Paste into ~/.ssh/config on your laptop for VS Code Remote-SSH"
  value       = <<-EOT
    Host ansible-control
      HostName ${aws_instance.control.public_ip}
      User ubuntu
      IdentityFile ~/.ssh/id_ed25519
      ForwardAgent yes
  EOT
}
