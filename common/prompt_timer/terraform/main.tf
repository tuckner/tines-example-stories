# test

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

resource "tines_agent" "search_user_by_email_in_slack" {
    name = "Search User by Email in Slack"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.send_message_to_user_in_slack_to_confirm.id]
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": "Bearer {{.CREDENTIAL.slack}}"}, "method": "get", "payload": {"email": "{{.receive_alert.body.email}}"}, "url": "https://slack.com/api/users.lookupByEmail"})
}

resource "tines_agent" "delay_event_1_hour" {
    name = "Delay Event 1 Hour"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.deduplicate_events.id]
    agent_options = jsonencode({"mode": "delay", "seconds": 3600})
}

resource "tines_agent" "catch_prompt_response" {
    name = "Catch Prompt Response"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.deduplicate_events.id]
    agent_options = jsonencode({"rules": [{"path": "{{.send_message_to_user_in_slack_to_confirm.prompt.status}}", "type": "regex", "value": "^$"}]})
}

resource "tines_agent" "send_message_to_user_in_slack_to_confirm" {
    name = "Send message to user in Slack to confirm"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.delay_event_1_hour.id, tines_agent.catch_prompt_response.id]
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": "Bearer {{.CREDENTIAL.slack}}"}, "log_error_on_status": [], "method": "post", "payload": {"attachments": [{"blocks": [{"text": {"text": "{{.receive_alerts.body.message}}", "type": "mrkdwn"}, "type": "section"}, {"fields": [{"text": "*action:*{% line_break %}{{.suspicious_alert_webhook.user_message}}", "type": "mrkdwn"}], "type": "section"}, {"elements": [{"style": "primary", "text": {"emoji": true, "text": "This Was Me", "type": "plain_text"}, "type": "button", "url": "{% prompt true %}"}, {"style": "danger", "text": {"emoji": true, "text": "I don\u0027t recognize this", "type": "plain_text"}, "type": "button", "url": "{% prompt invalid %}"}], "type": "actions"}]}], "channel": "{{.search_user_by_email_in_slack.body.user.id}}"}, "url": "https://slack.com/api/chat.postMessage"})
}

resource "tines_agent" "deduplicate_events" {
    name = "Deduplicate Events"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.user_confirmed.id, tines_agent.no_response.id]
    agent_options = jsonencode({"lookback": "100", "mode": "deduplicate", "path": "{% story_run_guid %}"})
}

resource "tines_agent" "user_confirmed" {
    name = "User Confirmed"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"rules": [{"path": "{{.send_message_to_user_in_slack_to_confirm.prompt.status}}", "type": "regex", "value": "true"}]})
}

resource "tines_agent" "no_response" {
    name = "No Response"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"rules": [{"path": "{{.delay_event_24_hours.delay}}", "type": "regex", "value": "."}]})
}
