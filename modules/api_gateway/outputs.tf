# modules/api_gateway/outputs.tf

output "api_gateway_url" {
  description = "The URL of the deployed API Gateway endpoint."
  value       = "${aws_api_gateway_stage.main.invoke_url}/hello"
}

output "api_gateway_rest_api_id" {
  description = "The ID of the API Gateway REST API."
  value       = aws_api_gateway_rest_api.main.id
}