
# Rearc Data Quest – Part 4 (Terraform)

This Terraform stack wires the whole pipeline:
1) An **ingest Lambda** that executes Part 1 & 2 (mirrors the BLS PR dataset and writes the population JSON to S3).
2) An **S3 event** that publishes to an **SQS queue** when a `.json` file lands under `part2/`.
3) A **report Lambda** that is triggered by SQS and logs the basic Part 3 statistics (mean/std for 2013–2018).

## How to use

```bash
terraform init
terraform apply -var="s3_bucket_name=<your-existing-bucket>"
```
