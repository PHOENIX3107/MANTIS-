variable "project_name" {
  type    = string
  default = "syncro1"
}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "ec2_instance_type" {
  type    = string
  default = "t3.small"
}

variable "rds_instance_class" {
  type    = string
  default = "db.t4g.small"
}

variable "rds_multi_az" {
  type    = bool
  default = false
}

variable "rds_master_username" {
  type      = string
  default   = "syncro1_admin"
  sensitive = true
}

variable "rds_master_secret_kms_key_id" {
  type      = string
  default   = ""
  sensitive = true
}

variable "db_name" {
  type    = string
  default = "mantis"
}

variable "ubuntu_ami_ssm_parameter" {
  type    = string
  default = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

variable "vpc_cidr" {
  type    = string
  default = "10.42.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.42.1.0/24", "10.42.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.42.11.0/24", "10.42.12.0/24"]
}

variable "upload_volume_size_gib" {
  type    = number
  default = 50
}

variable "artifact_bucket_name" {
  type    = string
  default = ""
}

variable "app_domain" {
  type    = string
  default = "bugs.syncro1.com"
}

variable "mail_from_domain" {
  type    = string
  default = "syncro1.com"
}

variable "create_route53_records" {
  type    = bool
  default = false
}

variable "route53_zone_id" {
  type    = string
  default = ""
}

variable "ops_alarm_email" {
  type      = string
  default   = ""
  sensitive = true
}

variable "ssm_parameter_arns" {
  description = "Existing SecureString parameter ARNs the EC2 role may read."
  type        = list(string)
  default     = []
}

variable "create_ssm_parameters" {
  description = "Create placeholder SecureString parameters from sensitive input variables. Prefer pre-provisioned parameters in production."
  type        = bool
  default     = false
}

variable "smtp_username" {
  type      = string
  default   = ""
  sensitive = true
}

variable "smtp_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "crypto_master_salt" {
  type      = string
  default   = ""
  sensitive = true
}

variable "route53_ttl" {
  type    = number
  default = 300
}
