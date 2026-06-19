output "instance_public_ip" {
  value = aws_instance.grafana.public_ip
}

output "grafana_url" {
  value = "http://${aws_instance.grafana.public_ip}:3000"
}

output "prometheus_url" {
  value = "http://${aws_instance.grafana.public_ip}:9090"
}

output "alertmanager_url" {
  value = "http://${aws_instance.grafana.public_ip}:9093"
}
