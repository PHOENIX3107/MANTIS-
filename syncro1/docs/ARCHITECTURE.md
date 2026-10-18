# SYNCRO1 architecture

```text
Users / staff
      |
  DNS -> Elastic IP
      |
EC2 public subnet (Ubuntu 24.04)
  nginx :80/:443 -- PHP-FPM -- MantisBT release
      |                 |
      |                 +-- EBS data volume -> /var/lib/syncro1/uploads
      +-------------------- private RDS MySQL 8.4
      |
      +-- SES SMTP submission (587/STARTTLS)
      +-- SSM Session Manager / CloudWatch agent

Private subnets: RDS subnet group across two AZs
Private S3 bucket: signed release tarballs
SNS: operational alarms
```

The EC2 security group exposes only HTTP/HTTPS. Administration is through SSM;
there is no SSH ingress. RDS accepts 3306 only from the EC2 security group and
is not public. Attachments are stored on the encrypted EBS volume outside the
web root. Terraform creates the daily EBS snapshot policy and RDS backups.

Development substitutes Docker Compose services for EC2/RDS/SES: PHP 8.3,
nginx, MySQL 8.4, Mailpit, and a queue helper.
