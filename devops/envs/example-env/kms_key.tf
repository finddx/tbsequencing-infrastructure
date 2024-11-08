resource "aws_kms_key" "sns_key" {
  count                   = var.chatbot_notifs_implementation ? 1 : 0
  description             = "Key used for encrypting the SNS topic for AWS Chatbot notifs."
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    Statement = [
      {
        "Sid" : "Allow_CloudWatch_for_CMK",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "events.amazonaws.com"
          ]
        },
        "Action" : [
          "kms:Decrypt",
          "kms:GenerateDataKey*",
        ],
        "Resource" : "*",
      },
      {
        Sid    = "Allow administration of the key"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action = [
          "kms:ReplicateKey",
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ],
        Resource = "*"
      },

    ]
  })
}
