data "aws_region" "current" {}

resource "aws_api_gateway_rest_api" "main" {
  name        = var.api_name
  description = "API Gateway for Cognito-authenticated Lambda"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = var.resource_path_part # e.g., "hello"
}

resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name                   = "${var.api_name}-cognito-authorizer"
  type                   = "COGNITO_USER_POOLS"
  rest_api_id            = aws_api_gateway_rest_api.main.id
  provider_arns          = [var.cognito_user_pool_arn]
  identity_source        = "method.request.header.Authorization" # Looks for JWT in Authorization header
  authorizer_result_ttl_in_seconds = 300 # Cache results for 5 minutes

  depends_on = [aws_api_gateway_rest_api.main]
}

resource "aws_api_gateway_method" "proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = var.http_method # e.g., "GET"
  authorization = "COGNITO_USER_POOLS" # Protect with Cognito authorizer
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy_method.http_method
  integration_http_method = "POST" # Lambda proxy integration typically uses POST
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn

  depends_on = [
    aws_api_gateway_method.proxy_method,
    aws_lambda_permission.api_gateway_lambda_permission,
  ]
}

resource "aws_lambda_permission" "api_gateway_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* part is essential for proxy integration, or a specific method path
  source_arn = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

#
# Gateway Response for Unauthorized requests (redirect to Cognito Hosted UI)
# This is key for the "ask for authentication" requirement.
#
resource "aws_api_gateway_gateway_response" "unauthorized_redirect" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  response_type = "UNAUTHORIZED" # Triggered when authorizer denies access
  status_code   = "302"          # HTTP Found (Redirection)

  response_parameters = {
    # The 'Location' header tells the browser where to redirect.
    # It constructs the Cognito Hosted UI URL.
    "gatewayresponse.header.Location" = "'https://${var.cognito_user_pool_domain}.auth.${data.aws_region.current.name}.amazoncognito.com/oauth2/authorize?response_type=token&client_id=${var.cognito_user_pool_client_id}&redirect_uri=${var.api_gateway_invoke_url}'"
  }
  # Minimal response templates, as the redirect header is primary
  response_templates = {
    "application/json" = jsonencode({ message = "Redirecting to Cognito login..." })
    "text/html"        = "<html><body><p>Redirecting to login...</p></body></html>"
  }

  depends_on = [
    aws_api_gateway_rest_api.main,
    aws_api_gateway_authorizer.cognito_authorizer
  ]
}

#
# CORS Setup for OPTIONS preflight requests
#
resource "aws_api_gateway_method" "proxy_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "OPTIONS"
  authorization = "NONE" # OPTIONS requests don't need auth
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy_options_method.http_method
  type        = "MOCK" # MOCK integration for CORS preflight
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy_options_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_200_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy_options_method.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code

  response_templates = {
    "application/json" = ""
  }

  # These values are returned in the actual OPTIONS response
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,GET,POST,PUT,DELETE,PATCH,HEAD'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'" # Be more specific in production to your frontend domain
  }
}

#
# Method and Integration Response for the Lambda (GET method)
# This ensures the HTML from Lambda is correctly served with CORS headers.
#
resource "aws_api_gateway_method_response" "proxy_method_200_response" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy_method.http_method
  status_code = "200"

  response_models = {
    "text/html" = "Empty" # Declare that the response can be text/html
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "lambda_integration_200_response" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy_method.http_method
  status_code = aws_api_gateway_method_response.proxy_method_200_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'" # Again, be specific in production
  }

  # CONVERT_TO_TEXT ensures API Gateway doesn't try to parse Lambda's output as JSON
  # if it's already a string of HTML.
  content_handling = "CONVERT_TO_TEXT"
  response_templates = {
    "text/html" = "$input.body" # Map Lambda's body directly to the HTML response
  }
}


resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = var.stage_name

  # Triggers redeployment when any changes occur in methods, integrations, or gateway responses
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy_method.id,
      aws_api_gateway_integration.lambda_integration.id,
      aws_api_gateway_gateway_response.unauthorized_redirect.id,
      aws_api_gateway_method_response.proxy_method_200_response.id, # For CORS headers
      aws_api_gateway_integration_response.lambda_integration_200_response.id, # For CORS headers
      aws_api_gateway_method.proxy_options_method.id,
      aws_api_gateway_integration.options_integration.id,
      aws_api_gateway_method_response.options_200.id,
      aws_api_gateway_integration_response.options_200_integration_response.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [triggers]
  }

  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_method.proxy_method,
    aws_api_gateway_resource.proxy,
    aws_api_gateway_gateway_response.unauthorized_redirect,
    aws_api_gateway_method.proxy_options_method,
    aws_api_gateway_method_response.proxy_method_200_response,
    aws_api_gateway_integration_response.lambda_integration_200_response
  ]
}