resource "aws_cloudwatch_event_rule" "step-function-failure-events" {
  count       = var.chatbot_notifs_implementation ? 1 : 0
  name        = "${local.service_name}-step-func-fail-abort-event"
  description = "Capture each AWS Step Function failure or abort"
  event_pattern = jsonencode({
    source = ["aws.states"]
    detail-type = [
      "Step Functions Execution Status Change"
    ]
    detail = {
      status = ["FAILED", "TIMED_OUT", "ABORTED"]
    }
  })
}

resource "aws_cloudwatch_event_target" "sns-target-rule" {
  count = var.chatbot_notifs_implementation ? 1 : 0
  rule  = resource.aws_cloudwatch_event_rule.step-function-failure-events[0].name
  arn   = resource.aws_sns_topic.step-func-fail[0].arn
  input_transformer {
    input_paths = {
      "exec" : "$.detail.name",
      "machine" : "$.detail.stateMachineArn",
      "region" : "$.region",
      "status" : "$.detail.status",
      "time" : "$.time",
      "url" : "$.detail.executionArn"
    }
    input_template = <<EOF
    {
    "version": "1.0",
    "source": "custom",
    "textType": "client-markdown",
    "content": {
      "description": "**Execution** [<exec>](https://<region>.console.aws.amazon.com/states/home?region=<region>#/v2/executions/details/<url>)",
      "title": ":warning: <machine> <status> at <time> :warning:"
      }
    }
  EOF
  }
}
