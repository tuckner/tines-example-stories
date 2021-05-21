terraform {
    required_providers {
        tines = {
        source = "github.com/tuckner/tines"
        version = ">=0.0.15"
        }
    }
}

provider "tines" {}

resource "tines_story" "throttle" {
    name = "Throttle"
    team_id = var.team_id
    description = <<EOF
This workflow allows for throttling of requests using AWS SQS and Tines scheduled actions. Here, a user can submit a form with some text. An SQS message will get entered and then stop at the Implode action. In the branch on the right, 'Receive SQS Message' will be scheduled to retrieve items from the queue once per minute. If it successfully retrieves a new message, it will pass the 'Check if Message' trigger and pass the event along to the implode action to join up the two branches.
EOF
}

resource "tines_global_resource" "aws_account" {
    name = "aws_account"
    value_type = "text"
    value = "replaceme"
    team_id = var.team_id
}

resource "tines_global_resource" "aws_region" {
    name = "aws_region"
    value_type = "text"
    value = "replaceme"
    team_id = var.team_id
}

resource "tines_global_resource" "sqs_queue" {
    name = "sqs_queue"
    value_type = "text"
    value = "replaceme"
    team_id = var.team_id
}

resource "tines_credential" "aws_key" {
    name = "aws_key"
    mode = "AWS"
    aws_access_key = "replaceme"
    aws_secret_key = "replaceme"
    team_id = var.team_id
}

resource "tines_agent" "send_sqs_message_0" {
    name = "Send SQS Message"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = tines_story.throttle.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.implode_an_array_4.id]
    position = {
      x = 217.0
      y = 327.0
    }
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": " {{ .CREDENTIAL.aws_key }}"}, "method": "get", "payload": {"Action": "SendMessage", "Expires": "2021-05-30T22%3A52%3A43PST", "MessageBody": "{{ .receive_form.body.text }}", "Version": "2012-11-05"}, "url": "https://sqs.{{ .RESOURCE.aws_region }}.amazonaws.com/{{ .RESOURCE.aws_account }}/{{ .RESOURCE.sqs_queue }}/"})
}

resource "tines_agent" "receive_sqs_message_1" {
    name = "Receive SQS Message"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = tines_story.throttle.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.check_if_message_7.id]
    position = {
      x = 427.0
      y = 102.0
    }
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": " {{ .CREDENTIAL.aws_key }}"}, "method": "get", "payload": {"Action": "ReceiveMessage", "AttributeName": "All", "Expires": "2021-05-30T22%3A52%3A43PST", "MaxNumberOfMessages": "1", "Version": "2012-11-05", "VisibilityTimeout": "15"}, "url": "https://sqs.{{ .RESOURCE.aws_region }}.amazonaws.com/{{ .RESOURCE.aws_account }}/{{ .RESOURCE.sqs_queue }}/"})
}

resource "tines_agent" "delete_sqs_message_2" {
    name = "Delete SQS Message"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = tines_story.throttle.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.implode_an_array_4.id]
    position = {
      x = 427.0
      y = 327.0
    }
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": " {{ .CREDENTIAL.aws_key }}"}, "method": "get", "payload": {"Action": "DeleteMessage", "Expires": "2021-05-30T22%3A52%3A43PST", "ReceiptHandle": "{{ .receive_sqs_message.body.ReceiveMessageResponse.ReceiveMessageResult.Message.ReceiptHandle }}", "Version": "2012-11-05"}, "url": "https://sqs.{{ .RESOURCE.aws_region }}.amazonaws.com/{{ .RESOURCE.aws_account }}/{{ .RESOURCE.sqs_queue }}/"})
}

resource "tines_agent" "receive_form_3" {
    name = "Receive Form"
    agent_type = "Agents::WebhookAgent"
    story_id = tines_story.throttle.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.message_text_5.id]
    position = {
      x = 217.0
      y = 177.0
    }
    agent_options = jsonencode({"secret": "12aee087893f7e845b4198e18c6edb6b", "verbs": "get,post"})
}

resource "tines_agent" "implode_an_array_4" {
    name = "Implode an Array"
    agent_type = "Agents::EventTransformationAgent"
    story_id = tines_story.throttle.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    position = {
      x = 330.0
      y = 420.0
    }
    agent_options = jsonencode({"guid_path": "{{ .message_text.message }}", "mode": "implode", "size_path": "2"})
}

resource "tines_agent" "message_text_5" {
    name = "Message Text"
    agent_type = "Agents::EventTransformationAgent"
    story_id = tines_story.throttle.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.send_sqs_message_0.id]
    position = {
      x = 217.0
      y = 252.0
    }
    agent_options = jsonencode({"mode": "message_only", "payload": {"message": "{{ .receive_form.body.text }}"}})
}

resource "tines_agent" "message_text_6" {
    name = "Message Text"
    agent_type = "Agents::EventTransformationAgent"
    story_id = tines_story.throttle.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    position = {
      x = 427.0
      y = 252.0
    }
    agent_options = jsonencode({"mode": "message_only", "payload": {"message": "{{ .receive_sqs_message.body.ReceiveMessageResponse.ReceiveMessageResult.Message.Body }}"}})
}

resource "tines_agent" "check_if_message_7" {
    name = "Check if Message"
    agent_type = "Agents::TriggerAgent"
    story_id = tines_story.throttle.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.message_text_6.id]
    position = {
      x = 427.0
      y = 177.0
    }
    agent_options = jsonencode({"rules": [{"path": "{{ .receive_sqs_message.body.ReceiveMessageResponse.ReceiveMessageResult.Message.Body }}", "type": "!regex", "value": "^$"}]})
}
