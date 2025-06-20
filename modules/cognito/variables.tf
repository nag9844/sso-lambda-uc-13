# modules/cognito/variables.tf

variable "project_name" {
  description = "The name of the overall project."
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, prod)."
  type        = string
}