output "vpc_id" {
  description = "VPC ID from the network module"
  value       = module.network.vpc_id
}

output "public_subnet_id" {
  value = module.network.public_subnet_id
}

output "private_subnet_id" {
  value = module.network.private_subnet_id
}

output "public_ec2_id" {
  value = module.compute.public_instance_id
}

output "private_ec2_id" {
  value = module.compute.private_instance_id
}

output "public_ec2_ip" {
  value = module.compute.public_ip
}

output "private_ec2_ip" {
  value = module.compute.private_ip
}

output "ec2_ami_id" {
  value = module.compute.ami_id
}