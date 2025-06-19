variable "user_pool_name" {
  description = "Name of the Cognito User Pool."
  type        = string
}

variable "app_client_name" {
  description = "Name of the Cognito User Pool App Client."
  type        = string
}

variable "auto_verified_attributes" {
  description = "List of attributes to be auto-verified (e.g., ['email', 'phone_number'])."
  type        = list(string)
  default     = ["email"]
}

variable "alias_attributes" {
  description = "Attributes supported as an alias for this user pool (e.g., ['email'])."
  type        = list(string)
  default     = ["email"]
}

variable "mfa_configuration" {
  description = "Multi-Factor Authentication (MFA) configuration for the User Pool. (OFF, ON, or OPTIONAL)."
  type        = string
  default     = "OFF"
}

variable "generate_app_client_secret" {
  description = "Whether to generate a client secret for the app client. Set to false for client-side applications."
  type        = bool
  default     = false
}

variable "allowed_oauth_flows" {
  description = "List of OAuth 2.0 flows allowed for the app client (e.g., ['code', 'implicit'])."
  type        = list(string)
  default     = ["implicit"]
}

variable "allowed_oauth_scopes" {
  description = "List of OAuth 2.0 scopes allowed for the app client (e.g., ['openid', 'email', 'profile'])."
  type        = list(string)
  default     = ["openid", "email", "profile"]
}

variable "callback_urls" {
  description = "List of allowed callback URLs for the app client (where Cognito redirects after login)."
  type        = list(string)
  default     = []
}

variable "logout_urls" {
  description = "List of allowed logout URLs for the app client (where Cognito redirects after logout)."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to assign to the Cognito resources."
  type        = map(string)
  default     = {}
}