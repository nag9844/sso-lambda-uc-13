# modules/lambda/main.tf

resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project_name}-${var.environment}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_exec_role.name
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/hello_world.py"
  output_path = "${path.module}/hello_world.zip"
}

resource "aws_lambda_function" "hello_world" {
  function_name    = "${var.project_name}-${var.environment}-hello-world"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "hello_world.lambda_handler"
  runtime          = "python3.9" # Or your preferred Python version
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}