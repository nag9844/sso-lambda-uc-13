
# Data sources to get current account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#
# AWS Cognito User Pool and App Client
#
module "cognito" {
  source = "./modules/cognito"

  user_pool_name             = "${var.project_name}-users"
  app_client_name            = "${var.project_name}-web-client"
  auto_verified_attributes   = ["email"]
  alias_attributes           = ["email"]
  generate_app_client_secret = false # IMPORTANT for web/mobile apps using implicit/auth code flow
  allowed_oauth_flows        = ["implicit"] # Or "code" with PKCE for better security
  allowed_oauth_scopes       = ["openid", "email", "profile"]
  
  # Callback and logout URLs will point to the API Gateway endpoint
  callback_urls              = ["${module.api_gateway.api_gateway_url}"]
  logout_urls                = ["${module.api_gateway.api_gateway_url}"]

  tags = var.common_tags
}

#
# AWS Cognito User Pool Domain (for Hosted UI)
# This resource requires a globally unique domain prefix.
#
resource "aws_cognito_user_pool_domain" "main_domain" {
  domain       = var.cognito_domain_prefix
  user_pool_id = module.cognito.user_pool_id
}

#
# AWS Lambda Function (Hello World HTML)
#
module "lambda" {
  source = "./modules/lambda"

  function_name       = "${var.project_name}-hello-handler"
  handler             = "index.handler"
  runtime             = "python3.12"
  source_path         = "${path.module}/modules/lambda/src" # Path to your Lambda code
  timeout             = 10 # seconds
  memory_size         = 128 # MB

  # Pass Cognito details as environment variables for client-side logout in HTML
  environment_variables = {
    USER_POOL_ID   = module.cognito.user_pool_id
    CLIENT_ID      = module.cognito.user_pool_client_id
    AWS_REGION     = data.aws_region.current.name
  }
  tags = var.common_tags
}

#
# AWS API Gateway (REST API with Cognito Authorizer)
#
module "api_gateway" {
  source = "./modules/api_gateway"

  api_name               = "${var.project_name}-web-api"
  resource_path_part     = "hello" # The path that will serve the authenticated page
  http_method            = "GET" # Only GET for serving a simple page
  lambda_invoke_arn      = module.lambda.lambda_invoke_arn
  lambda_function_name   = module.lambda.lambda_function_name
  cognito_user_pool_arn  = module.cognito.user_pool_arn
  cognito_user_pool_client_id = module.cognito.user_pool_client_id
  cognito_user_pool_domain    = aws_cognito_user_pool_domain.main_domain.domain
  stage_name             = var.api_gateway_stage_name

  # The api_gateway_invoke_url output needs to be available for the cognito module's callback URLs.
  # We construct it here to avoid circular dependency with module.api_gateway.api_gateway_url
  # that isn't known until after deployment.
  api_gateway_invoke_url = "https://${aws_api_gateway_rest_api.api_gateway.id}.execute-api.${data.aws_region.current.name}/${var.api_gateway_stage_name}/${var.resource_path_part}"

  tags = var.common_tags

  # Explicit dependencies to ensure resources are created in order
  depends_on = [
    module.cognito,
    module.lambda,
    aws_cognito_user_pool_domain.main_domain
  ]
}

# A data source to get the API Gateway REST API ID after its creation by the module
# This helps in constructing the full invoke URL correctly for the Cognito callback
# Note: This is usually implicitly handled by the module outputs, but explicit use
# can sometimes help with ordering or specific needs if outputs aren't directly available.
resource "aws_api_gateway_rest_api" "api_gateway" {
  # This resource is technically created by the module.api_gateway. We are only
  # creating a 'proxy' reference here to solve the circular dependency on the URL.
  # In a more advanced scenario, you might pass the API ID out of the module.
  # For this specific case, the `api_gateway_invoke_url` construction above is often enough.
  # If you face "computed value" issues for `api_gateway_invoke_url`, consider:
  # 1. Hardcoding the domain: https://<API_ID>.execute-api.<region>.amazonaws.com/<stage>/hello
  # 2. Or, run `terraform apply` twice. The first run creates API Gateway,
  #    then the second run populates `api_gateway_invoke_url` for Cognito.
  # For now, the current construction of api_gateway_invoke_url is a common workaround.
  name        = module.api_gateway.api_name
  description = "Temporary reference to API Gateway created by module"
  lifecycle {
    ignore_changes = all # Crucial: Don't manage this resource directly, it's owned by the module.
  }
}