output "db_instance_address" {
  description = "Hostname of the RDS instance"
  value       = aws_db_instance.this.address
}

output "db_instance_endpoint" {
  description = "Connection endpoint"
  value       = aws_db_instance.this.endpoint
}

output "db_instance_port" {
  description = "Port of the RDS instance"
  value       = aws_db_instance.this.port
}
