output "ec2_instance_id" {
  value = aws_instance.app.id
}

output "elastic_ip" {
  value = aws_eip.app.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.rds.address
}

output "rds_master_secret_arn" {
  value     = aws_db_instance.rds.master_user_secret[0].secret_arn
  sensitive = true
}

output "artifact_bucket" {
  value = aws_s3_bucket.artifacts.bucket
}

output "ses_verification_dns" {
  value = {
    type  = "TXT"
    name  = "_amazonses.${var.mail_from_domain}"
    value = aws_ses_domain_identity.mail.verification_token
  }
}

output "ses_dkim_dns" {
  value = [for token in aws_ses_domain_dkim.mail.dkim_tokens : {
    type  = "CNAME"
    name  = "${token}._domainkey.${var.mail_from_domain}"
    value = "${token}.dkim.amazonses.com"
  }]
}

output "ses_mail_from_dns" {
  value = {
    mx = {
      name  = "bounce.${var.mail_from_domain}"
      value = "feedback-smtp.${var.aws_region}.amazonses.com"
    }
    spf = {
      name  = "bounce.${var.mail_from_domain}"
      value = "v=spf1 include:amazonses.com ~all"
    }
  }
}

output "ssm_connect_command" {
  value = "aws ssm start-session --target ${aws_instance.app.id} --region ${var.aws_region}"
}
