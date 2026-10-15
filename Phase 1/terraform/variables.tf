variable "region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Prefix for resource names"
  type        = string
  default     = "cloud-fleet"
}

variable "vpc_cidr" {
  type    = string
}

variable "subnet_cidr" {
  type    = string
 
}

variable "instance_type" {
  type    = string
}

variable "managed_count" {
  description = "Number of managed nodes"
  type        = number
  default     = 1
}

variable "public_key_path" {
  description = "Path to your SSH public key on the laptop"
  type        = string
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR form, e.g. 203.0.113.7/32 (allowed to SSH to the control node)"
  type        = string
}

variable "app_port" {
  description = "Port the application listens on (opened on managed nodes)"
  type        = number
  default     = 80
}
