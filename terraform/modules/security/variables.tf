variable "vpc_id" {
  type = string
}


variable "project_name" {
  type = string
}

variable "allowed_ssh_cidr" {
  description = "Public IPv4 address allowed to SSH, with /32"
  type        = string
}