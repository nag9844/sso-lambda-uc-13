# ------------------------------------------------
# Outputs
# ------------------------------------------------
output "api_gateway_url" {
  description = "The URL of the API Gateway endpoint."
  value       = module.api_gateway.api_gateway_url
}

output "cognito_user_pool_id" {
  description = "The ID of the Cognito User Pool."
  value       = module.cognito.user_pool_id
}

output "cognito_user_pool_client_id" {
  description = "The ID of the Cognito User Pool Client."
  value       = module.cognito.user_pool_client_id
}