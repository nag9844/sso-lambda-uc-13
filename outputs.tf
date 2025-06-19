output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}

output "cognito_user_pool_client_id" {
  description = "Cognito User Pool App Client ID"
  value       = module.cognito.user_pool_client_id
}

output "cognito_hosted_ui_domain" {
  description = "The URL for your Cognito Hosted UI."
  value       = "https://${aws_cognito_user_pool_domain.main_domain.domain}.auth.${var.aws_region}.amazoncognito.com"
}

output "api_gateway_invoke_url" {
  description = "API Gateway Invoke URL for the authenticated 'Hello World' page."
  value       = module.api_gateway.api_gateway_url
}

output "lambda_function_name" {
  description = "Lambda Function Name"
  value       = module.lambda.lambda_function_name
}