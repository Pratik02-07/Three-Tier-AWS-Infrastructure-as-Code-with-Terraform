#!/bin/bash

dnf update -y
dnf install -y httpd

systemctl enable httpd
systemctl start httpd

# Fetch Availability Zone using secure IMDSv2 token
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)

cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Frontend Server</title>
</head>
<body style="font-family: Arial; text-align: center; margin-top: 100px;">
    <h1>Welcome to Frontend Server</h1>
    <h3>Environment: ${environment}</h3>
    <h3>Hostname: $(hostname)</h3>
    <h3>Availability Zone: $AZ</h3>
</body>
</html>
EOF
