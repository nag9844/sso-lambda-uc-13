# modules/api_gateway/main.tf

resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.project_name}-${var.environment}-api"
  description = "API Gateway for Hello World web page with Cognito authentication."

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_api_gateway_resource" "hello_world_resource" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "hello" # e.g., /hello
}

resource "aws_api_gateway_method" "hello_world_method" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.hello_world_resource.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS" # This is the key for Cognito auth
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "hello_world_integration" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.hello_world_resource.id
  http_method             = aws_api_gateway_method.hello_world_method.http_method
  type                    = "AWS_PROXY" # Lambda Proxy Integration
  integration_http_method = "POST"      # Lambda integrations use POST
  uri                     = var.lambda_function_arn
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowAPIGatewayInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_arn
  principal     = "apigateway.amazonaws.com"
  # The "source_arn" ensures that only this specific API Gateway can invoke the Lambda
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  # Force a new deployment when any resource/method/integration changes
  # This makes sure changes are applied to the API Gateway
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.hello_world_resource.id,
      aws_api_gateway_method.hello_world_method.id,
      aws_api_gateway_integration.hello_world_integration.id,
      aws_api_gateway_authorizer.cognito.id # Include authorizer in trigger
    ]))
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      # Ignore changes to description field as it is managed by the console.
      # If you make changes to description via console, terraform will try to revert them
      # unless this is ignored
      description,
    ]
  }
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.environment

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_api_gateway_authorizer" "cognito" {
  name                   = "${var.project_name}-${var.environment}-cognito-authorizer"
  rest_api_id            = aws_api_gateway_rest_api.main.id
  type                   = "COGNITO_USER_POOLS"
  provider_arns          = [var.cognito_user_pool_arn]
  identity_source        = "method.request.header.Authorization" # Token passed in Authorization header
}