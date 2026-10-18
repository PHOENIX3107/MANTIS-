data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ssm_parameter" "ubuntu_ami" {
  name = var.ubuntu_ami_ssm_parameter
}

data "aws_caller_identity" "current" {}

locals {
  name = var.project_name
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)
  tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
  }
  artifact_bucket = var.artifact_bucket_name != "" ? var.artifact_bucket_name : "${var.project_name}-${data.aws_caller_identity.current.account_id}-releases"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(local.tags, { Name = "${local.name}-vpc" })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.tags, { Name = "${local.name}-igw" })
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true
  tags                    = merge(local.tags, { Name = "${local.name}-public-${count.index + 1}" })
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]
  tags              = merge(local.tags, { Name = "${local.name}-private-${count.index + 1}" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = merge(local.tags, { Name = "${local.name}-public-rt" })
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ec2" {
  name        = "${local.name}-ec2"
  description = "Public web ingress; administration through SSM only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name}-ec2-sg" })
}

resource "aws_security_group" "rds" {
  name        = "${local.name}-rds"
  description = "MySQL only from the SYNCRO1 EC2 security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from application EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name}-rds-sg" })
}

resource "aws_db_subnet_group" "rds" {
  name       = "${local.name}-rds-subnets"
  subnet_ids = aws_subnet.private[*].id
  tags       = merge(local.tags, { Name = "${local.name}-rds-subnets" })
}

resource "aws_db_parameter_group" "rds" {
  name   = "${local.name}-mysql84"
  family = "mysql8.4"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  tags = local.tags
}

resource "aws_db_instance" "rds" {
  identifier                    = "${local.name}-mysql"
  engine                        = "mysql"
  engine_version                = "8.4"
  instance_class                = var.rds_instance_class
  allocated_storage             = 20
  max_allocated_storage         = 100
  storage_type                  = "gp3"
  storage_encrypted             = true
  db_name                       = var.db_name
  username                      = var.rds_master_username
  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.rds_master_secret_kms_key_id != "" ? var.rds_master_secret_kms_key_id : null
  multi_az                      = var.rds_multi_az
  db_subnet_group_name          = aws_db_subnet_group.rds.name
  vpc_security_group_ids        = [aws_security_group.rds.id]
  parameter_group_name          = aws_db_parameter_group.rds.name
  backup_retention_period       = 14
  backup_window                 = "18:00-18:30"
  maintenance_window            = "sun:19:00-sun:19:30"
  deletion_protection           = true
  skip_final_snapshot           = false
  final_snapshot_identifier     = "${local.name}-final"
  publicly_accessible           = false
  copy_tags_to_snapshot         = true
  apply_immediately             = false
  tags                          = merge(local.tags, { Name = "${local.name}-rds" })
}

resource "aws_iam_role" "ec2" {
  name = "${local.name}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy" "secrets" {
  count = length(var.ssm_parameter_arns) > 0 ? 1 : 0
  name  = "${local.name}-read-config"
  role  = aws_iam_role.ec2.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter", "ssm:GetParameters"]
      Resource = var.ssm_parameter_arns
    }]
  })
}

resource "aws_iam_role_policy" "artifacts" {
  name = "${local.name}-read-artifacts"
  role = aws_iam_role.ec2.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = "${aws_s3_bucket.artifacts.arn}/releases/*"
    }]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${local.name}-ec2-profile"
  role = aws_iam_role.ec2.name
}

resource "aws_instance" "app" {
  ami                         = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type               = var.ec2_instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  user_data                   = file("${path.module}/user-data.sh")
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 20
  }

  tags = merge(local.tags, { Name = "${local.name}-app" })
}

resource "aws_eip" "app" {
  domain   = "vpc"
  instance = aws_instance.app.id
  tags     = merge(local.tags, { Name = "${local.name}-eip" })
}

resource "aws_ebs_volume" "uploads" {
  availability_zone = aws_subnet.public[0].availability_zone
  size              = var.upload_volume_size_gib
  type              = "gp3"
  encrypted         = true
  tags              = merge(local.tags, { Name = "${local.name}-uploads" })
}

resource "aws_volume_attachment" "uploads" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.uploads.id
  instance_id = aws_instance.app.id
}

resource "aws_iam_role" "dlm" {
  name = "${local.name}-dlm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "dlm.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "dlm" {
  role       = aws_iam_role.dlm.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
}

resource "aws_dlm_lifecycle_policy" "uploads" {
  description        = "Daily encrypted SYNCRO1 uploads snapshots"
  execution_role_arn = aws_iam_role.dlm.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]
    target_tags = {
      Name = "${local.name}-uploads"
    }

    schedule {
      name = "daily"
      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["03:00"]
      }
      retain_rule {
        count = 14
      }
      tags_to_add = {
        SnapshotType = "syncro1-daily"
      }
    }
  }
}

resource "aws_s3_bucket" "artifacts" {
  bucket        = local.artifact_bucket
  force_destroy = false
  tags          = merge(local.tags, { Name = local.artifact_bucket })
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_sns_topic" "ops" {
  name = "${local.name}-ops"
  tags = local.tags
}

resource "aws_sns_topic_subscription" "ops_email" {
  count     = var.ops_alarm_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.ops.arn
  protocol  = "email"
  endpoint  = var.ops_alarm_email
}

resource "aws_cloudwatch_metric_alarm" "ec2_status" {
  alarm_name          = "${local.name}-ec2-status"
  alarm_description   = "EC2 status check failure"
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed_System"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions          = { InstanceId = aws_instance.app.id }
  alarm_actions       = [aws_sns_topic.ops.arn]
}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name          = "${local.name}-ec2-cpu"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  dimensions          = { InstanceId = aws_instance.app.id }
  alarm_actions       = [aws_sns_topic.ops.arn]
}

resource "aws_cloudwatch_metric_alarm" "ec2_disk" {
  alarm_name          = "${local.name}-ec2-disk"
  namespace           = "CWAgent"
  metric_name         = "disk_used_percent"
  statistic           = "Maximum"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  dimensions          = { InstanceId = aws_instance.app.id, device = "/dev/root", fstype = "ext4", path = "/" }
  alarm_actions       = [aws_sns_topic.ops.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${local.name}-rds-cpu"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  dimensions          = { DBInstanceIdentifier = aws_db_instance.rds.id }
  alarm_actions       = [aws_sns_topic.ops.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${local.name}-rds-free-storage"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 2
  threshold           = 5368709120
  comparison_operator = "LessThanThreshold"
  dimensions          = { DBInstanceIdentifier = aws_db_instance.rds.id }
  alarm_actions       = [aws_sns_topic.ops.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${local.name}-rds-connections"
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  statistic           = "Maximum"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  dimensions          = { DBInstanceIdentifier = aws_db_instance.rds.id }
  alarm_actions       = [aws_sns_topic.ops.arn]
}

resource "aws_ses_domain_identity" "mail" {
  domain = var.mail_from_domain
}

resource "aws_ses_domain_dkim" "mail" {
  domain = aws_ses_domain_identity.mail.domain
}

resource "aws_ses_domain_mail_from" "mail" {
  domain           = aws_ses_domain_identity.mail.domain
  mail_from_domain = "bounce.${var.mail_from_domain}"
}

resource "aws_ssm_parameter" "smtp_username" {
  count       = var.create_ssm_parameters ? 1 : 0
  name        = "/${local.name}/smtp/username"
  description = "SYNCRO1 SMTP username"
  type        = "SecureString"
  value       = var.smtp_username
  tags        = local.tags
}

resource "aws_ssm_parameter" "smtp_password" {
  count       = var.create_ssm_parameters ? 1 : 0
  name        = "/${local.name}/smtp/password"
  description = "SYNCRO1 SMTP password"
  type        = "SecureString"
  value       = var.smtp_password
  tags        = local.tags
}

resource "aws_ssm_parameter" "crypto_salt" {
  count       = var.create_ssm_parameters ? 1 : 0
  name        = "/${local.name}/crypto/master-salt"
  description = "Stable SYNCRO1 crypto master salt"
  type        = "SecureString"
  value       = var.crypto_master_salt
  tags        = local.tags
}

resource "aws_route53_record" "app" {
  count   = var.create_route53_records ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.app_domain
  type    = "A"
  ttl     = var.route53_ttl
  records = [aws_eip.app.public_ip]
}
