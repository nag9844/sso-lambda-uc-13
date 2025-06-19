output "lambda_function_arn" {
  description = "The ARN of the Lambda function."
  value       = aws_lambda_function.main.arn
}

output "lambda_invoke_arn" {
  description = "The invoke ARN of the Lambda function."
  value       = aws_lambda_function.main.invoke_arn
}

output "lambda_function_name" {
  description = "The name of the Lambda function."
  value       = aws_lambda_function.main.function_name
}