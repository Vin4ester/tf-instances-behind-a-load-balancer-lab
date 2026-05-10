variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "project_id" {
  description = "Project ID used for tagging resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

variable "public_subnet_a_id" {
  description = "ID of the public subnet A"
  type        = string
}

variable "public_subnet_b_id" {
  description = "ID of the public subnet B"
  type        = string
}

variable "ssh_inbound_id" {
  description = "ID of the security group that allows SSH access"
  type        = string
}

variable "http_inbound_id" {
  description = "ID of the security group that allows HTTP access to EC2"
  type        = string
}

variable "lb_http_inbound_id" {
  description = "ID of the security group that allows HTTP access to the load balancer"
  type        = string
}

variable "iam_instance_profile" {
  description = "Name of the IAM instance profile for EC2 instances"
  type        = string
}

variable "key_name" {
  description = "Name of the key pair for SSH access"
  type        = string
}

variable "aws_launch_template_name" {
  description = "Name of the Launch Template"
  type        = string
}

variable "aws_asg_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
}

variable "load_balancer" {
  description = "Name of the Application Load Balancer"
  type        = string
}
