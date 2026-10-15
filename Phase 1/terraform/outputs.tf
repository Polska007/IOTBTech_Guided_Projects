output "control_public_ip" {
  value = aws_instance.control.public_ip
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
