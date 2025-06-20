# modules/api_gateway/variables.tf

variable "project_name" {
  description = "The name of the overall project."
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, prod)."
  type        = string
}

variable "lambda_function_arn" {
  description = "The ARN of the Lambda function to integrate with."
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "The ARN of the Cognito User Pool for authorization."
  type        = string
}