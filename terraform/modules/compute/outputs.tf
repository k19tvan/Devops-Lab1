output "public_instance_id" {
  value = aws_instance.public.id
}

output "private_instance_id" {
  value = aws_instance.private.id
}

output "public_ip" {
  value = aws_instance.public.public_ip
}

output "private_ip" {
  value = aws_instance.private.private_ip
}

output "ami_id" {
  value = data.aws_ami.amazon_linux.id
}