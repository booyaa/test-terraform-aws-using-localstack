variable lambda_zip_file_name {
  type = string
  default = "src.zip"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "../src"

  output_path = var.lambda_zip_file_name
}

resource "aws_lambda_function" "s3_lambda" {
  function_name    = "s3_lambda_function"
  role             = aws_iam_role.function_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  timeout          = "900"
  filename         = var.lambda_zip_file_name
  source_code_hash = filebase64sha256(var.lambda_zip_file_name)
}

# Create a bucket
resource "aws_s3_bucket" "test-bucket" {
  bucket = "test-bucket-070"
}

output "bucket_name" {
  value = aws_s3_bucket.test-bucket.bucket
}

resource "aws_s3_bucket_acl" "test-bucket-acl" {
  bucket = aws_s3_bucket.test-bucket.id
  acl    = "public-read" # or can be "private"
}

resource "aws_s3_bucket_notification" "s3_lambda_trigger" {
  bucket = aws_s3_bucket.test-bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

resource "aws_lambda_permission" "s3_lambda_permission" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.test-bucket.arn //"arn:aws:s3:::${aws_s3_bucket.test-bucket.id}"
}

resource "aws_cloudwatch_log_group" "function_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.s3_lambda.function_name}"
  retention_in_days = 7
  lifecycle {
    prevent_destroy = false
  }
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.function_log_group.name
}

resource "aws_iam_role" "function_role" {
  name = "function-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Action : "sts:AssumeRole",
        Effect : "Allow",
        Principal : {
          "Service" : "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "s3_full_access_policy" {
  name   = "s3_full_access_policy"
  role   = aws_iam_role.function_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "s3:*",
      Resource = [
       "${aws_s3_bucket.test-bucket.arn}",
        "${aws_s3_bucket.test-bucket.arn}/*",
      ],
    }],
  })
}

resource "aws_iam_policy" "function_logging_policy" {
  name = "function-logging-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Action : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect : "Allow",
        Resource : "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "function_logging_policy_attachment" {
  role       = aws_iam_role.function_role.id
  policy_arn = aws_iam_policy.function_logging_policy.arn
}

