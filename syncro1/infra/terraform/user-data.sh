#!/bin/bash
set -eu

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y amazon-cloudwatch-agent nginx
systemctl enable amazon-ssm-agent 2>/dev/null || true
systemctl enable amazon-cloudwatch-agent 2>/dev/null || true
mkdir -p /opt/syncro1 /etc/syncro1
chmod 0750 /opt/syncro1 /etc/syncro1
