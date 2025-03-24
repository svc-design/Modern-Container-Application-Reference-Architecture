output "vpc_id" {
  value = aws_vpc.devops.id
}

output "subnet_web" {
  value = aws_subnet.subnet_web.id
}

output "subnet_db" {
  value = aws_subnet.subnet_db.id
}
