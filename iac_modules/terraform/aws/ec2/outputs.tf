output "public_ip" {
  value = aws_instance.devops.public_ip
}

output "private_ip" {
  value = aws_instance.devops.private_ip
}
