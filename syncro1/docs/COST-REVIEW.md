# Terraform cost review

Review date: 2026-10-19. No prices are stated here because no AWS account
pricing query was performed.

## Plan evidence

Command executed with the committed example variables:

```text
docker run --rm -e AWS_EC2_METADATA_DISABLED=true \
  -v "$PWD/syncro1/infra/terraform:/work" -w /work \
  hashicorp/terraform:1.9.8 plan -refresh=false -input=false \
  -var-file=terraform.tfvars.example -no-color
```

Terraform initialized successfully with provider `hashicorp/aws v5.100.0`.
The plan could not complete because this workspace has no AWS credentials:

```text
Changes to Outputs:
  + ses_mail_from_dns = {
      + mx  = {
          + name  = "bounce.syncro1.com"
          + value = "feedback-smtp.ap-south-1.amazonses.com"
        }
      + spf = {
          + name  = "bounce.syncro1.com"
          + value = "v=spf1 include:amazonses.com ~all"
        }
    }

Error: No valid credential sources found
Error: failed to refresh cached credentials, no EC2 IMDS role found
```

Therefore this is a configuration/resource review, not a claim that a
provider-backed plan passed. `terraform validate` and `terraform fmt -check`
were separate syntax checks; they do not verify AWS availability or prices.

## Resources in the configuration

| Terraform resources | Cost or operational implication | Strictly required? |
|---|---|---|
| `aws_instance.app` | EC2 compute; also incurs attached root EBS storage | Yes, for the single-host deployment |
| `aws_db_instance.rds` | RDS compute, allocated/max storage, backups and snapshots | Yes, if the database is managed by RDS |
| `aws_ebs_volume.uploads` and `aws_volume_attachment.uploads` | Persistent gp3 upload storage; snapshot storage is separate | Yes, for durable disk uploads |
| `aws_eip.app` | Elastic IP allocation; attached to the app instance in this design | Operational choice; avoid if DNS/ALB is used instead |
| `aws_dlm_lifecycle_policy.uploads` | Creates retained EBS snapshots; snapshot storage is billable | Recovery control, not required for serving traffic |
| `aws_s3_bucket.artifacts` plus versioning/encryption/public-access resources | S3 storage, requests, and retained object versions; deployment artifact bucket | Deployment support, not runtime-required if artifacts are supplied another way |
| `aws_sns_topic.ops` and optional `aws_sns_topic_subscription.ops_email` | SNS usage; email subscription is created only when `ops_alarm_email` is non-empty | Monitoring choice |
| Six `aws_cloudwatch_metric_alarm` resources | CloudWatch alarm charges; `CWAgent` disk metrics may also create metric/log usage | Monitoring choice |
| `aws_ses_domain_identity`, DKIM, and MAIL FROM resources | SES sending/related usage when email is sent; identity/DNS setup is not the application runtime | Required only for production email delivery |
| Optional `aws_ssm_parameter.smtp_username`, `smtp_password`, `crypto_salt` | Secure parameter storage/usage according to the selected SSM tier | Not created by `terraform.tfvars.example` (`create_ssm_parameters=false`) |
| Optional `aws_route53_record.app` | Route 53 record/query usage if enabled; the hosted zone is external to this module | Not created by example (`create_route53_records=false`) |
| `aws_vpc`, IGW, two public/two private subnets, route table/associations, and security groups | Core networking constructs; no NAT gateway resource is present | VPC/SGs/subnets are required for the selected EC2/RDS layout |
| IAM roles, policies, attachments, and instance profile | No direct service charge; permissions for SSM, CloudWatch, DLM, and artifacts | Required for the enabled operational integrations |
| RDS parameter/subnet groups | No separate compute charge; required configuration objects for RDS | Required by the RDS design |

## Explicit flags

- NAT gateways: none are defined. This avoids NAT gateway hourly/data charges;
  the current EC2 host is public and the RDS instance is private.
- Multi-AZ: `rds_multi_az` defaults to `false` in the example, so the RDS
  instance is not Multi-AZ. The network still creates public and private
  subnets in two availability zones. `aws_db_subnet_group.rds` uses both
  private subnets, while the EC2 instance uses only `public[0]`.
- Not strictly required for the minimum single-host application: the second
  public subnet, monitoring alarms/SNS, DLM snapshots, the artifact bucket,
  and the Elastic IP are operational/resilience choices. The second private
  subnet is used by the RDS subnet group even though RDS Multi-AZ is false.
- No price estimate is included. Final cost requires the selected AWS region,
  account pricing, data volume, snapshot retention, email volume, and actual
  CloudWatch/S3 usage to be verified before deployment.
