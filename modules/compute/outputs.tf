output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.alb.dns_name
}

output "alb_security_group_id" {
  description = "ID of the Application Load Balancer Security Group"
  value       = aws_security_group.alb.id
}

output "frontend_security_group_id" {
  description = "ID of the Frontend Web Security Group"
  value       = aws_security_group.frontend.id
}

output "backend_security_group_id" {
  description = "ID of the Backend App Security Group"
  value       = aws_security_group.backend.id
}

output "frontend_asg_name" {
  description = "Name of the Frontend Auto Scaling Group"
  value       = aws_autoscaling_group.frontend.name
}

output "backend_asg_name" {
  description = "Name of the Backend Auto Scaling Group"
  value       = aws_autoscaling_group.backend.name
}