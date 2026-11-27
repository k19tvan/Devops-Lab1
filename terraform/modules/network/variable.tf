variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC"
  type        = string
}

variable "project_name" {
  description = "Prefix used to name project resources"
  type        = string
}

variable "availability_zone" {
  description = "Availability Zone for the subnets"
  type        = string
}

variable "public_subnet_cidr" {
  description = "IPv4 CIDR block for the public subnet"
  type        = string
}

variable "private_subnet_cidr" {
  description = "IPv4 CIDR block for the private subnet"
  type        = string
}