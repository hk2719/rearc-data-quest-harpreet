
variable "project_name" {
  description = "A short name used for tagging and resource names."
  type        = string
  default     = "rearc-dataquest"
}

variable "aws_region" {
  description = "AWS region to deploy to."
  type        = string
  default     = "us-east-2"
}

variable "s3_bucket_name" {
  description = "Destination S3 bucket that already exists (created in Part 1)."
  type        = string
}

variable "s3_event_prefix" {
  description = "Only S3 keys with this prefix will publish to SQS."
  type        = string
  default     = "part2/"
}

variable "s3_event_suffix" {
  description = "Only S3 keys with this suffix will publish to SQS."
  type        = string
  default     = ".json"
}

variable "ingest_schedule_expression" {
  description = "EventBridge schedule to run the ingest Lambda (cron or rate)."
  type        = string
  default     = "rate(1 day)"
}

variable "datausa_population_api" {
  description = "DataUSA population API endpoint used in Part 2."
  type        = string
  default     = "https://honolulu-api.datausa.io/tesseract/data.jsonrecords?cube=acs_yg_total_population_1&drilldowns=Year%2CNation&locale=en&measures=Population"
}

variable "population_s3_key" {
  description = "S3 object key where the Part 2 JSON result will be written."
  type        = string
  default     = "part2/population_data.json"
}

variable "enable_bls_part1_sync" {
  description = "If true, the ingest Lambda will also mirror the BLS PR dataset from Part 1."
  type        = bool
  default     = true
}

variable "bls_base_url" {
  description = "Base URL for BLS PR time-series dataset (Part 1)."
  type        = string
  default     = "https://download.bls.gov/pub/time.series/pr/"
}

variable "tags" {
  description = "Tags to set on created resources."
  type        = map(string)
  default = {
    Project = "Rearc Data Quest"
    Part    = "4"
    Owner   = "Terraform"
  }
}
