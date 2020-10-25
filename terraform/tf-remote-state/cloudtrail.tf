resource "aws_s3_bucket" "tf_remote_state_cloudtrail" {
  bucket        = "aws-setup-tf-remote-state-cloudtrail"
  acl           = "private"
  force_destroy = true

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
          "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::aws-setup-tf-remote-state-cloudtrail"
    },
    {
      "Effect": "Allow",
      "Principal": {
          "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::aws-setup-tf-remote-state-cloudtrail/*",
      "Condition": {
          "StringEquals": {
              "s3:x-amz-acl": "bucket-owner-full-control"
          }
      }
    }
  ]
}
EOF

  tags = local.tags
}

resource "aws_s3_bucket_public_access_block" "tf_remote_state_cloudtrail" {
  bucket                  = aws_s3_bucket.tf_remote_state_cloudtrail.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudtrail" "tf_remote_state_cloudtrail" {
  name                  = "tf-remote-state-cloudtrail"
  s3_bucket_name        = aws_s3_bucket.tf_remote_state_cloudtrail.bucket
  is_multi_region_trail = true

  event_selector {
    read_write_type           = "WriteOnly"
    include_management_events = false

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.tf_remote_state.arn}/"]
    }
  }

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.tf_remote_state_cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.tf_remote_state_cloudtrail.arn

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "tf_remote_state_cloudtrail" {
  name = "CloudTrail/TfRemoteStateCloudTrailWriteLogs"
  tags = local.tags
}

resource "aws_iam_role" "tf_remote_state_cloudtrail" {
  name = "tf-remote-state-cloudtrail"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

}

resource "aws_iam_policy" "tf_remote_state_cloudtrail_cloudwatch_logs" {
  name        = "TfRemoteStateCloudTrailWriteCloudwatchLogs"
  description = "Allow Cloudtrail for terraform remote state to write logs to cloudwatch"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.tf_remote_state_cloudtrail.name}:log-stream:${data.aws_caller_identity.current.account_id}_CloudTrail_${data.aws_region.current.name}*"
      ]
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "cloudwatch_write" {
  role       = aws_iam_role.tf_remote_state_cloudtrail.name
  policy_arn = aws_iam_policy.tf_remote_state_cloudtrail_cloudwatch_logs.arn
}
