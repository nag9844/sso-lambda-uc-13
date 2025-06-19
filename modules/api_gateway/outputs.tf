output "api_gateway_url" {
  description = "The base URL of the deployed API Gateway, including stage and resource path."
  # This output assumes the deployment stage is immediately active on the path.
  # For the purpose of the callback_url and for simple access, this is the most useful.
  value       = "${aws_api_gateway_deployment.main.invoke_url}/${var.resource_path_part}"
}

output "api_gateway_execution_arn" {
  description = "The execution ARN of the API Gateway."
  value       = aws_api_gateway_rest_api.main.execution_arn
}

output "api_gateway_id" {
  description = "The ID of the API Gateway REST API."
  value       = aws_api_gateway_rest_api.main.id
}