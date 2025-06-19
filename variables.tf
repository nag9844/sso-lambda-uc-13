variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "ap-south-1" # Mumbai region
}

variable "project_name" {
  description = "A prefix for all resource names."
  type        = string
  default     = "MyHelloAuthApp" # Choose a unique prefix
}

variable "api_gateway_stage_name" {
  description = "The name of the API Gateway deployment stage."
  type        = string
  default     = "dev"
}

variable "cognito_domain_prefix" {
  description = "The custom domain prefix for your Cognito User Pool Hosted UI (e.g., 'myauthapp-login'). MUST BE GLOBALLY UNIQUE."
  type        = string
  # IMPORTANT: Replace with a unique value, e.g., "myhelloapp-login-12345"
  default     = "myhelloapp-login-unique"
}

variable "common_tags" {
  description = "Common tags to apply to all resources."
  type        = map(string)
  default = {
    Environment = "development"
    Project     = "UserAuthHelloDemo"
    ManagedBy   = "Terraform"
  }
}

variable "resource_path_part" {
  description = "The path part for the API Gateway resource (e.g., 'hello')."
  type        = string
  default     = "hello" # Match what you set in the api_gateway module call
}