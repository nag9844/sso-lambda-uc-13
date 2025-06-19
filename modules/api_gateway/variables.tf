variable "api_name" {
  description = "Name of the API Gateway REST API."
  type        = string
}

variable "resource_path_part" {
  description = "The path part for the API Gateway resource (e.g., 'hello')."
  type        = string
}

variable "http_method" {
  description = "The HTTP method for the API Gateway resource (e.g., 'GET')."
  type        = string
}

variable "lambda_invoke_arn" {
  description = "The invoke ARN of the Lambda function to integrate with API Gateway."
  type        = string
}

variable "lambda_function_name" {
  description = "The name of the Lambda function to grant permissions to."
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "The ARN of the Cognito User Pool to use as an authorizer."
  type        = string
}

variable "cognito_user_pool_client_id" {
  description = "The ID of the Cognito User Pool App Client, used in the redirect URL."
  type        = string
}

variable "cognito_user_pool_domain" {
  description = "The domain prefix for the Cognito User Pool Hosted UI (e.g., 'yourprefix')."
  type        = string
}

variable "api_gateway_invoke_url" {
  description = "The full invoke URL of the API Gateway, used as redirect_uri for Cognito."
  type        = string
}

variable "stage_name" {
  description = "The name of the API Gateway deployment stage (e.g., 'dev', 'prod')."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "A map of tags to assign to the API Gateway resources."
  type        = map(string)
  default     = {}
}