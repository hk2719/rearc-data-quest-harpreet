
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  name = "${var.project_name}-${random_id.suffix.hex}"
}

resource "random_id" "suffix" {
  byte_length = 2
}

# ------------------------
# SQS queue for Part 2 S3 notifications
# ------------------------
resource "aws_sqs_queue" "reports" {
  name                       = "${local.name}-reports-queue"
  message_retention_seconds  = 86400
  visibility_timeout_seconds = 60
  tags                       = var.tags
}

# Allow S3 bucket to send messages to SQS
data "aws_iam_policy_document" "sqs_allow_s3" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions   = ["SQS:SendMessage"]
    resources = [aws_sqs_queue.reports.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:s3:::${var.s3_bucket_name}"]
    }
  }
}

resource "aws_sqs_queue_policy" "reports" {
  queue_url = aws_sqs_queue.reports.id
  policy    = data.aws_iam_policy_document.sqs_allow_s3.json
}

# ------------------------
# S3 -> SQS notification (fires when part2 JSON lands)
# ------------------------
resource "aws_s3_bucket_notification" "notify_queue" {
  bucket = var.s3_bucket_name

  queue {
    queue_arn     = aws_sqs_queue.reports.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = var.s3_event_prefix
    filter_suffix = var.s3_event_suffix
  }

  depends_on = [aws_sqs_queue_policy.reports]
}

# ------------------------
# Lambda: ingest (Parts 1 & 2)
# ------------------------
data "archive_file" "lambda_ingest_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_ingest"
  output_path = "${path.module}/build/lambda_ingest.zip"
}

resource "aws_iam_role" "lambda_ingest" {
  name               = "${local.name}-ingest-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Minimal permissions to read web, write to S3, write logs
data "aws_iam_policy_document" "lambda_ingest_inline" {
  statement {
    effect  = "Allow"
    actions = ["s3:PutObject", "s3:PutObjectAcl", "s3:ListBucket", "s3:GetObject"]
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
      "arn:aws:s3:::${var.s3_bucket_name}/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lambda_ingest_inline" {
  role   = aws_iam_role.lambda_ingest.id
  policy = data.aws_iam_policy_document.lambda_ingest_inline.json
}

resource "aws_lambda_function" "ingest" {
  function_name = "${local.name}-ingest"
  role          = aws_iam_role.lambda_ingest.arn
  handler       = "main.lambda_handler"
  runtime       = "python3.11"
  filename      = data.archive_file.lambda_ingest_zip.output_path
  timeout       = 900

  environment {
    variables = {
      S3_BUCKET             = var.s3_bucket_name
      POPULATION_S3_KEY     = var.population_s3_key
      DATAUSA_POP_API       = var.datausa_population_api
      ENABLE_BLS_PART1_SYNC = tostring(var.enable_bls_part1_sync)
      BLS_BASE_URL          = var.bls_base_url
    }
  }

  tags = var.tags
}

# Scheduled trigger (once a day by default)
resource "aws_cloudwatch_event_rule" "ingest_schedule" {
  name                = "${local.name}-ingest-schedule"
  schedule_expression = var.ingest_schedule_expression
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "ingest_target" {
  rule = aws_cloudwatch_event_rule.ingest_schedule.name
  arn  = aws_lambda_function.ingest.arn
}

resource "aws_lambda_permission" "allow_events_to_invoke_ingest" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingest.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ingest_schedule.arn
}

# ------------------------
# Lambda: report (Part 3) consumes SQS
# ------------------------
data "archive_file" "lambda_report_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_report"
  output_path = "${path.module}/build/lambda_report.zip"
}

resource "aws_iam_role" "lambda_report" {
  name               = "${local.name}-report-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "lambda_report_inline" {
  statement {
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
      "arn:aws:s3:::${var.s3_bucket_name}/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
    resources = [aws_sqs_queue.reports.arn]
  }
}

resource "aws_iam_role_policy" "lambda_report_inline" {
  role   = aws_iam_role.lambda_report.id
  policy = data.aws_iam_policy_document.lambda_report_inline.json
}

resource "aws_lambda_function" "report" {
  function_name = "${local.name}-report"
  role          = aws_iam_role.lambda_report.arn
  handler       = "main.lambda_handler"
  runtime       = "python3.11"
  filename      = data.archive_file.lambda_report_zip.output_path
  timeout       = 60

  environment {
    variables = {
      S3_BUCKET         = var.s3_bucket_name
      POPULATION_S3_KEY = var.population_s3_key
    }
  }

  tags = var.tags
}

# Wire SQS to Lambda (polling)
resource "aws_lambda_event_source_mapping" "sqs_to_report" {
  event_source_arn = aws_sqs_queue.reports.arn
  function_name    = aws_lambda_function.report.arn
  batch_size       = 5
  enabled          = true
}
