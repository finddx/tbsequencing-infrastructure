resource "aws_sns_topic" "step-func-fail" {
  count             = var.chatbot_notifs_implementation ? 1 : 0
  name              = "${local.prefix}-step-func-fail-topic"
  kms_master_key_id = var.chatbot_notifs_implementation ? resource.aws_kms_key.sns_key[0].key_id : null
}

resource "aws_sns_topic_subscription" "step-func-fail" {
  count     = var.chatbot_notifs_implementation ? 1 : 0
  topic_arn = resource.aws_sns_topic.step-func-fail[0].arn
  protocol  = "https"
  endpoint  = "https://global.sns-api.chatbot.amazonaws.com"
}

data "aws_iam_policy_document" "sns_topic_policy" {
  count     = var.chatbot_notifs_implementation ? 1 : 0
  policy_id = "${local.prefix}-alarm-chatbot-sns-policy"

  statement {
    actions = [
      "sns:Publish"
    ]
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [
      aws_sns_topic.step-func-fail[0].arn,
    ]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [resource.aws_cloudwatch_event_rule.step-function-failure-events[0].arn]
    }
  }
}

resource "aws_sns_topic_policy" "default" {
  count  = var.chatbot_notifs_implementation ? 1 : 0
  arn    = aws_sns_topic.step-func-fail[0].arn
  policy = data.aws_iam_policy_document.sns_topic_policy[0].json
}
