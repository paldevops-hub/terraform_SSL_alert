resource "aws_sns_topic" "ssl_expiry_notifications" {
  name = "ssl-expiry-notifications"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.ssl_expiry_notifications.arn
  protocol  = "email"
  endpoint  = "your-email@example.com" // Replace with your email address
}


###############################################################


resource "aws_iam_role" "lambda_role" {
  name = "ssl_expiry_checker_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Effect = "Allow",
    }]
  })
}

resource "aws_lambda_function" "ssl_expiry_checker" {
  filename      = "ssl.zip"
  function_name = "ssl_expiry_checker"
  role          = aws_iam_role.lambda_role.arn
  handler       = "ssl_expiry_checker.lambda_handler"  # Adjust the handler according to your Lambda function
  runtime       = "python3.8"  # Adjust the runtime according to your needs
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ssl_expiry_checker.function_name
  principal     = "events.amazonaws.com"
}

resource "aws_cloudwatch_event_rule" "every_day" {
  name                = "every-day"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "check_ssl_expiry" {
  rule      = aws_cloudwatch_event_rule.every_day.name
  target_id = "ssl_expiry_checker"
  arn       = aws_lambda_function.ssl_expiry_checker.arn
}
