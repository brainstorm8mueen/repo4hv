output "web_public_ip" { value = aws_instance.web.public_ip }
output "web_public_dns" { value = aws_instance.web.public_dns }
output "db_private_ip" { value = aws_instance.db.private_ip }
output "application_url" { value = "http://${aws_instance.web.public_ip}:${var.app_port}" }
