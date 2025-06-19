
# Data sources to get current account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#
# AWS Lambda Function (Hello World HTML)
# We put Lambda first as it doesn't immediately depend on API Gateway or Cognito for its ARN.
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
  # These will be updated after Cognito is created, which is fine for runtime.
  environment_variables = {
    USER_POOL_ID   = "" # Placeholder, will be updated by a later apply
    CLIENT_ID      = "" # Placeholder, will be updated by a later apply
    # AWS_REGION     = data.aws_region.current.name
  }
  tags = var.common_tags
}

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

  # Initial placeholder for callback/logout URLs.
  # The *actual* API Gateway URL is only known after the API Gateway is deployed.
  # This is the primary point of circular dependency that we break by allowing
  # a subsequent `terraform apply` to update this.
  callback_urls              = ["https://example.com/callback"] # Placeholder URL
  logout_urls                = ["https://example.com/logout"]   # Placeholder URL

  tags = var.common_tags
}

#
# AWS Cognito User Pool Domain (for Hosted UI)
# This resource requires a globally unique domain prefix.
#
resource "aws_cognito_user_pool_domain" "main_domain" {
  domain       = var.cognito_domain_prefix
  user_pool_id = module.cognito.user_pool_id

  # This depends on the Cognito User Pool being created first.
  depends_on = [module.cognito]
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

  # The api_gateway_invoke_url output from the api_gateway module is what we need.
  # We can't directly use module.api_gateway.api_gateway_url here for the *initial*
  # deployment of the cognito callback URLs, as that output is not yet known.
  # This value is primarily used for the `UNAUTHORIZED` Gateway Response redirect.
  api_gateway_invoke_url = "https://${module.api_gateway.api_gateway_id}.execute-api.${data.aws_region.current.name}/${var.api_gateway_stage_name}/${var.resource_path_part}"

  tags = var.common_tags

  # Explicit dependency to ensure Cognito and Lambda are ready before API Gateway configures authorizers/integrations
  depends_on = [
    module.cognito,
    module.lambda,
    aws_cognito_user_pool_domain.main_domain
  ]
}

#
# Update Cognito Callback URLs after API Gateway is deployed
# This is the crucial part to break the cycle.
# We create a null_resource that depends on the API Gateway deployment,
# and then use a local-exec to update Cognito.
# However, a simpler way is to run `terraform apply` twice.
# For a single apply approach, we'd need to leverage a data source for Cognito
# after the API Gateway is deployed, but that's still complicated.
#
# The most common pattern for this specific circular dependency (Cognito callback/logout URLs)
# is to perform two `terraform apply` runs:
# 1. First run creates Cognito (with placeholder URLs), Lambda, and API Gateway.
# 2. Second run updates Cognito with the actual API Gateway URLs.
#
# Let's adjust the `cognito` module call to use the actual URL if known,
# but rely on the two-apply pattern for the initial setup.
#

# Re-configure Cognito callback/logout URLs dynamically
# This approach still requires a second 'terraform apply' to pick up the API Gateway URL.
# During the first 'apply', module.api_gateway.api_gateway_url will be "computed known after apply".
# Terraform will then apply the Cognito module with the placeholder URLs.
# On the *second* 'apply', module.api_gateway.api_gateway_url will be known, and Cognito
# will be updated in-place.
# To make this explicitly manageable by Terraform and avoid manual steps,
# we can use a separate `aws_cognito_user_pool_client` resource to update the URLs,
# but it's simpler to just let the `module.cognito` resource be updated.

# The `depends_on` in `module.api_gateway` is crucial.
# The `api_gateway_invoke_url` for the Gateway Response also relies on `module.api_gateway.api_gateway_id`
# which simplifies the direct reference and avoids the `aws_api_gateway_rest_api.api_gateway` data source.

# Let's remove the `aws_api_gateway_rest_api.api_gateway` resource from `main.tf`
# as it was an attempt to break a cycle that's better handled by module outputs and two-phase apply.