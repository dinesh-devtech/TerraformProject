output "instance_public_ip" {
  description = "Public IP of EC2"
  value = aws_instance.public_ip
}
