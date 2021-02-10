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

resource "tines_agent" "prompt_response_0" {
    name = "Prompt Response"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.remove_containment_5.id]
    agent_options = jsonencode({"rules": [{"path": "{{.post_message_to_a_slack_channel.prompt.status}}", "type": "field==value", "value": "remove_containment"}]})
}

resource "tines_agent" "receive_host_details_1" {
    name = "Receive Host Details"
    agent_type = "Agents::WebhookAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.contain_device_4.id]
    agent_options = jsonencode({"secret": "4eb0108d09a0df52c26b1f5a0d8dde91", "verbs": "get,post"})
}

resource "tines_agent" "build_results_2" {
    name = "Build Results"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.containment_unsuccessful_8.id, tines_agent.containment_successful_9.id]
    agent_options = jsonencode({"mode": "message_only", "payload": {"containment_successful": "{% if .contain_device.status == 202 %}true{% else %}false{% endif %}", "errors": "{{.contain_device.body.errors | as_object}}", "time_contained": "{{ \u0027now\u0027 | date: \u0027%Y-%m-%dT%H:%M:%S%z\u0027 }}"}})
}

resource "tines_agent" "send_to_story_agent_3" {
    name = "Send to Story Agent"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"payload": {"host_id": "cc0904730de3470eb5570c5f648f6716"}, "story": "{% story Crowdstrike - Contain Device %}"})
}

resource "tines_agent" "contain_device_4" {
    name = "Contain Device"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.build_results_2.id]
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": "Bearer {{.CREDENTIAL.crowdstrike}}"}, "method": "post", "payload": {"action_parameters": [{"name": "", "value": ""}], "ids": ["{{.receive_host_details.body.host_id}}"]}, "url": "https://api.{{.RESOURCE.crowdstrike_domain}}/devices/entities/devices-actions/v2?action_name=contain"})
}

resource "tines_agent" "remove_containment_5" {
    name = "Remove Containment"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"payload": {"host_id": "{{.receive_host_details.body.host_id}}"}, "story": "{% story Crowdstrike - Lift Device Containment %}"})
}

resource "tines_agent" "post_message_to_a_slack_channel_6" {
    name = "Post Message to a Slack Channel"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.prompt_response_0.id]
    agent_options = jsonencode({"content_type": "json", "headers": {}, "method": "post", "payload": {"text": "A machine has been contained in Crowdstrike Falcon\n*Host ID:* {{.receive_host_details.body.host_id}}\n*Time:* {{.build_results.time_contained}}\n\nClick \u003c{% prompt remove_containment %}|here\u003e to lift the network isolation on this machine."}, "url": "{{.RESOURCE.slack_webhook_url}}"})
}

resource "tines_agent" "post_message_to_a_slack_channel_7" {
    name = "Post Message to a Slack Channel"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"content_type": "json", "headers": {}, "method": "post", "payload": {"text": "An attempt to contain a machine in Crowdstrike Falcon has *failed*\n*Host ID:* {{.receive_host_details.body.host_id}}\n*Time:* {{.build_results.time_contained}}\n*Error:* {{.contain_device.body.errors.first}}"}, "url": "{{.RESOURCE.slack_webhook_url}}"})
}

resource "tines_agent" "containment_unsuccessful_8" {
    name = "Containment Unsuccessful"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.post_message_to_a_slack_channel_7.id]
    agent_options = jsonencode({"rules": [{"path": "{{.contain_device.status}}", "type": "field!=value", "value": "202"}]})
}

resource "tines_agent" "containment_successful_9" {
    name = "Containment Successful"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.post_message_to_a_slack_channel_6.id]
    agent_options = jsonencode({"rules": [{"path": "{{.contain_device.status}}", "type": "field==value", "value": "202"}]})
}
