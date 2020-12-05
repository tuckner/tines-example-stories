terraform {
    required_providers {
        tines = {
        source = "github.com/tuckner/tines"
        version = ">=0.0.7"
        }
    }
}

provider "tines" {
    email    = var.tines_email
    base_url = var.tines_base_url
    token    = var.tines_token
}

provider "aws" {
  region    = "us-east-1"
}

### Begin AWS
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

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

resource "aws_lambda_function" "levenshtein_example" {
  filename      = "resources/levenshtein.zip"
  function_name = "levenshtein_example"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda_function.lambda_handler"
  runtime = "python2.7"
}

### Begin Tines

resource "tines_global_resource" "vip_list_example" {
  name = "vip_list_example"
  value_type = "json"
  value = "{\"vips\": [\"eoin@tines.io\", \"thomas@tines.io\"]}"
}

resource "tines_agent" "fuzzy_match_lambda_function" {
    name = "Fuzzy Match Lambda Function"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.trigger_agent.id]
    agent_options = format(jsonencode({"url": "https://lambda.us-east-1.amazonaws.com/2015-03-31/functions/%s/invocations?x-amz-log-type=None&x-amz-invocation-type=RequestResponse", "headers": {"Authorization": " {{ .CREDENTIAL.aws_us_east_1_lambda}}"}, "method": "post", "content_type": "json", "payload": {"str2": "{{ .explode_vip.vip}}", "str1": "{{ .calculate_similarity.body.str1}}"}}), aws_lambda_function.levenshtein_example.function_name)
}

resource "tines_agent" "calculate_similarity" {
    name = "Calculate Similarity"
    agent_type = "Agents::WebhookAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.explode_vip.id]
    agent_options = jsonencode({"secret": "8bfabdd44138867ba24751cdc818af62", "verbs": "get,post"})
}

resource "tines_agent" "send_to_story_agent" {
    name = "Send to Story Agent"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"story": "{% story VIP Fuzzy Matching %}", "payload": {"str1": "e0in@tones.io"}})
}

resource "tines_agent" "trigger_agent" {
    name = "Trigger Agent"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.return_results.id]
    agent_options = jsonencode({"rules": [{"path": "{{ .fuzzy_match_lambda_function.body.ratio }}", "type": "field>=value", "value": "75"}]})
}

resource "tines_agent" "return_results" {
    name = "Return Results"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"mode": "message_only", "payload": {"message": "{{ .calculate_similarity.body.str1 }} is a pretty close match to {{ .explode_vip.vip}}"}})
}

resource "tines_agent" "explode_vip" {
    name = "Explode VIP"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.fuzzy_match_lambda_function.id]
    agent_options = format(jsonencode({"path": "{{.RESOURCE.%s.vips | as_object }}", "mode": "explode", "to": "vip"}), tines_global_resource.vip_list_example.name)
}

