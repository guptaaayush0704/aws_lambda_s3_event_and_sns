#-----------------------
# Cloud Provider
#-----------------------

provider "aws" {
  region = "us-east-1"
}

#-----------------------
# Data Blocks
#-----------------------

data aws_caller_identity current {}
 
data aws_iam_policy_document lambda_policy_document {
   statement {
     actions = [
         "logs:CreateLogGroup",
         "logs:CreateLogStream",
         "logs:PutLogEvents"
     ]
     effect = "Allow"
     resources = [ "*" ]
   }

  statement {
     actions = [
       "events:PutRule",
       "events:ListRules",
       "events:PutTargets",
       "events:PutPermission"
     ]
     effect = "Allow"
     resources = [ "*" ]
   }
 
   statement {
     actions = [
       "s3 : PutObject"
     ]
     effect = "Allow"
     resources = [ "*" ]
   }
}

#-----------------------
# Resources
#-----------------------


#------------------------------------------------------------
# IAM Role for Lambda
#------------------------------------------------------------

resource aws_iam_role lambda_role {
 name = "ec2-state-change-lambda-role"
 managed_policy_arns = [aws_iam_policy.lambda_policy.arn]
 assume_role_policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
       {
           "Action": "sts:AssumeRole",
           "Principal": {
               "Service": "lambda.amazonaws.com"
           },
           "Effect": "Allow"
       }
   ]
}
 EOF

  tags = {
    owner     = var.owner
    }
}

#------------------------------------------------------------
# IAM policy for Lambda
#------------------------------------------------------------

resource aws_iam_policy lambda_policy {
   name = "ec2-state-change-lambda-policy"
   path = "/"
   policy = data.aws_iam_policy_document.lambda_policy_document.json
   tags = {
      owner     = var.owner
    }
}


#------------------------------------------------------------
# AWS Lambda Function
#------------------------------------------------------------

resource aws_lambda_function ec2-state-change-lambda {
description       = "The function to put json object to s3 for ec2 state changes"
function_name     = "ec2-state-change-lambda"
role              = aws_iam_role.lambda_role.arn
filename          = "lambda_function_payload.zip"
timeout           = 300
memory_size       = "256"
handler           = "index.py"
source_code_hash  = filebase64sha256("lambda_function_payload.zip")
tags = {
      owner       = var.owner
    }
}
 

#------------------------------------------------------------
# Cloudwatch Event Rule
#------------------------------------------------------------

resource aws_cloudwatch_event_rule rule {
    name                = var.function_name
    description         = "Invokes the ${var.function_name} Lambda"
    event_pattern = <<EOF
      {
        "source": ["aws.ec2"],
        "detail-type": [
        "EC2 Instance State-change Notification"
        ]
      }
      EOF
    tags = {
      owner     = var.owner
    }
}


#------------------------------------------------------------
# Cloudwatch Event Target
#------------------------------------------------------------

resource aws_cloudwatch_event_target target {
    rule      = aws_cloudwatch_event_rule.rule.name
    target_id = var.function_name
    arn       = aws_lambda_function.ec2-state-change-lambda.arn
}


#------------------------------------------------------------
# LAmbda Invoke Permission 
#------------------------------------------------------------

resource aws_lambda_permission permission {
    statement_id  = "AllowExecutionFromCloudWatchEvent"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.ec2-state-change-lambda.function_name
    principal     = "events.amazonaws.com"
    source_arn    = aws_cloudwatch_event_rule.rule.arn
}


#------------------------------------------------------------
#  Output AWS Lambda id
#------------------------------------------------------------

output "lambda_name" {
 value = aws_lambda_function.ec2-state-change-lambda.id
}
