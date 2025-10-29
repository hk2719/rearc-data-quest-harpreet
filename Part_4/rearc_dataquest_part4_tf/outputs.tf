
output "queue_url" {
  value = aws_sqs_queue.reports.id
}

output "queue_arn" {
  value = aws_sqs_queue.reports.arn
}

output "ingest_lambda_name" {
  value = aws_lambda_function.ingest.function_name
}

output "report_lambda_name" {
  value = aws_lambda_function.report.function_name
}
