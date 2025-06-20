# modules/cognito/main.tf

resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}-${var.environment}-user-pool"

  # Minimal configuration for a basic setup
  # Consider more robust password policies, MFA, etc., for production.
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  auto_verified_attributes = ["email"]

  schema {
    name     = "email"
    attribute_data_type = "String"
    mutable  = true
    required = true
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.project_name}-${var.environment}-app-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # Important for web applications
  explicit_auth_flows = ["ADMIN_NO_SRP_AUTH", "USER_PASSWORD_AUTH"]

  # For a basic web page, we often don't need a client secret.
  # If you were building a mobile app or a secure backend, you might want it.
  generate_secret = false

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}