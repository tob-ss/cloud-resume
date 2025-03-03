  # DynamoDB table for visitor counter
resource "aws_dynamodb_table" "visitor_counter" {
    name         = "${var.environment}-visitor-counter"
    billing_mode = "PAY_PER_REQUEST"
    hash_key     = "id"

    attribute {
      name = "id"
      type = "S"
    }

    tags = merge(
      var.tags,
      {
        Name        = "${var.environment}-visitor-counter"
        Environment = var.environment
      }
    )
  }

  # Create initial counter record if it doesn't exist
resource "aws_dynamodb_table_item" "visitor_counter" {
    table_name = aws_dynamodb_table.visitor_counter.name
    hash_key   = aws_dynamodb_table.visitor_counter.hash_key

    item = <<ITEM
  {
    "id": {"S": "visitors"},
    "count": {"N": "0"}
  }
  ITEM
  }

  # IAM role for Lambda function
resource "aws_iam_role" "lambda_role" {
    name = "${var.environment}-visitor-counter-lambda-role"

    assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
  }

  # IAM policy for Lambda to access DynamoDB
resource "aws_iam_policy" "lambda_policy" {
    name        = "${var.environment}-visitor-counter-lambda-policy"
    description = "Policy for visitor counter Lambda"

    policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ],
        "Resource": "${aws_dynamodb_table.visitor_counter.arn}",
        "Effect": "Allow"
      },
      {
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:*:*:*",
        "Effect": "Allow"
      }
    ]
  }
  EOF
  }

  # Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
    role       = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.lambda_policy.arn
  }

  # Lambda layer for dependencies
resource "null_resource" "lambda_dependencies" {
    provisioner "local-exec" {
      command = <<EOF
  cd ${path.module}/../../../../../lambda && npm install
  EOF
    }

    triggers = {
      dependencies_versions = filemd5("${path.module}/../../../../../lambda/package.json")
    }
  }

  data "archive_file" "lambda_layer_zip" {
    type        = "zip"
    output_path = "${path.module}/../../../../../lambda/layer.zip"
    source_dir  = "${path.module}/../../../../../lambda/node_modules"

    depends_on = [null_resource.lambda_dependencies]
  }

resource "aws_lambda_layer_version" "dependencies" {
    layer_name          = "${var.environment}-visitor-counter-dependencies"
    filename            = data.archive_file.lambda_layer_zip.output_path
    source_code_hash    = data.archive_file.lambda_layer_zip.output_base64sha256
    compatible_runtimes = ["nodejs20.x"]

    depends_on = [data.archive_file.lambda_layer_zip]
  }

  # Lambda function code
  data "archive_file" "lambda_zip" {
    type        = "zip"
    output_path = "${path.module}/../../../../../lambda/function.zip"
    source_dir  = "${path.module}/../../../../../lambda/function"
  }

  # Lambda function
resource "aws_lambda_function" "visitor_counter" {
    function_name    = "${var.environment}-visitor-counter"
    filename         = data.archive_file.lambda_zip.output_path
    source_code_hash = data.archive_file.lambda_zip.output_base64sha256
    role             = aws_iam_role.lambda_role.arn
    handler          = "index.handler"
    runtime          = "nodejs20.x"
    timeout          = 10
    layers           = [aws_lambda_layer_version.dependencies.arn]

    environment {
      variables = {
        TABLE_NAME = aws_dynamodb_table.visitor_counter.name
      }
    }

    tags = merge(
      var.tags,
      {
        Name        = "${var.environment}-visitor-counter"
        Environment = var.environment
      }
    )

    depends_on = [aws_lambda_layer_version.dependencies]
  }

  # API Gateway
resource "aws_apigatewayv2_api" "api" {
    name          = "${var.environment}-visitor-counter-api"
    protocol_type = "HTTP"
    cors_configuration {
      allow_origins = ["*"]
      allow_methods = ["GET", "OPTIONS"]
      allow_headers = ["content-type"]
      max_age       = 300
    }
  }

  # API Gateway stage
resource "aws_apigatewayv2_stage" "default" {
    api_id      = aws_apigatewayv2_api.api.id
    name        = "$default"
    auto_deploy = true
  }

  # API Gateway integration with Lambda
resource "aws_apigatewayv2_integration" "lambda_integration" {
    api_id             = aws_apigatewayv2_api.api.id
    integration_type   = "AWS_PROXY"
    integration_uri    = aws_lambda_function.visitor_counter.invoke_arn
    integration_method = "POST"
    payload_format_version = "2.0"
  }

  # API Gateway route
resource "aws_apigatewayv2_route" "get_count" {
    api_id    = aws_apigatewayv2_api.api.id
    route_key = "GET /count"
    target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
  }

  # Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
    statement_id  = "AllowExecutionFromAPIGateway"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.visitor_counter.function_name
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
  }