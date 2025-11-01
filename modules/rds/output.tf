output "db-hostname" {
  value = aws_db_instance.database.address
}

output "db-port" {
  value = aws_db_instance.database.port
}

output "db-username" {
  value = aws_db_instance.database.username
}

output "db-arn" {
  value = aws_db_instance.database.arn
}