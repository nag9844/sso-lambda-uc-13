resource "aws_cognito_user_pool" "main" {
  name = var.user_pool_name

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  auto_verified_attributes = var.auto_verified_attributes
  alias_attributes         = var.alias_attributes

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
    # For production, consider using SES by setting source_arn and from_email_address
    # source_arn = "arn:aws:ses:REGION:ACCOUNT_ID:identity/YOUR_VERIFIED_EMAIL"
    # from_email_address = "noreply@yourdomain.com"
  }

  mfa_configuration = var.mfa_configuration

  tags = var.tags
}

resource "aws_cognito_user_pool_client" "main" {
  name                                 = var.app_client_name
  user_pool_id                         = aws_cognito_user_pool.main.id
  generate_secret                      = var.generate_app_client_secret # Set to false for web/mobile apps

  allowed_oauth_flows_user_pool_client = true # Enable OAuth flows
  allowed_oauth_flows                  = var.allowed_oauth_flows # e.g., ["implicit"]
  allowed_oauth_scopes                 = var.allowed_oauth_scopes # e.g., ["openid", "email", "profile"]
  callback_urls                        = var.callback_urls
  logout_urls                          = var.logout_urls

  # Authentication flows enabled for this client. USER_SRP_AUTH is for username/password.
  # ALLOW_REFRESH_TOKEN_AUTH is crucial for refreshing tokens.
  explicit_auth_flows = ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]

  prevent_user_existence_errors = "ENABLED" # Good security practice

  # tags = var.tags
}