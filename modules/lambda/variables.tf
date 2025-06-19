variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
}

variable "handler" {
  description = "The function entrypoint in your Lambda code (e.g., index.handler)."
  type        = string
}

variable "runtime" {
  description = "The runtime environment for the Lambda function (e.g., nodejs20.x, python3.12)."
  type        = string
}

variable "source_path" {
  description = "Path to the directory containing your Lambda function code."
  type        = string
}

variable "timeout" {
  description = "The amount of time (in seconds) that Lambda allows a function to run before stopping it."
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "The amount of memory in MB that your Lambda function has available."
  type        = number
  default     = 128
}

variable "environment_variables" {
  description = "A map of environment variables for the Lambda function."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A map of tags to assign to the Lambda resources."
  type        = map(string)
  default     = {}
}