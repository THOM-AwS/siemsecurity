resource "aws_kms_key" "siem_key" {
  description             = "KMS key for SIEM"
  deletion_window_in_days = 10
  policy                  = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_kms_alias" "siem_key_alias" {
  name          = "alias/siem_key"
  target_key_id = aws_kms_key.siem_key.id
}

data "aws_caller_identity" "current" {}
