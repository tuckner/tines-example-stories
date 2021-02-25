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

resource "tines_agent" "verify_a_domain_0" {
    name = "Verify a Domain"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"payload": {"payload": {"data": [{"domain": "tines.dev", "inboundType": "known"}]}, "uri": "/api/domain/verify-domain"}, "send_payload_as_body": "false", "story": "{% story Mimecast STS %}"})
}

resource "tines_agent" "get_threat_intel_feed_1" {
    name = "Get Threat Intel Feed"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"payload": {"payload": {"data": [{"start": "2021-02-20T10:15:30+0000"}]}, "uri": "/api/ttp/threat-intel/get-feed"}, "send_payload_as_body": "false", "story": "{% story Mimecast STS %}"})
}

resource "tines_agent" "query_mimecast_2" {
    name = "Query Mimecast"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.return_results_5.id]
    agent_options = jsonencode({"content_type": "application/json", "headers": {"Authorization": "MC {{ access-key }}:{{ signature | base64_encode }}", "x-mc-app-id": "{{ app-id }}", "x-mc-date": "{{ date }}", "x-mc-req-id": "{{ req-id }}"}, "method": "post", "payload": "{{.webhook_agent.payload | as_object }}", "placeholders": ["{% capture uri %}{{.webhook_agent.uri}}{% endcapture %}", "{% capture app-id %}{% credential mimecast-app-id %}{% endcapture %}", "{% capture app-key %}{% credential mimecast-app-key %}{% endcapture %}", "{% capture access-key %}{% credential mimecast-access-key %}{% endcapture %}", "{% capture secret-key-cred %}{% credential mimecast-secret-key %}{% endcapture %}{% capture secret-key %}{{ secret-key-cred | base64_decode }}{% endcapture %}", "{% capture date %}{{ \u0027now\u0027 | date: \u0027%a, %e %b %Y %H:%M:%S %Z\u0027 }}{% endcapture %}", "{% capture req-id %}{% story_run_guid %}{% endcapture %}", "{% capture data-to-sign %}{{date}}:{{req-id}}:{{uri}}:{{app-key}}{% endcapture %}", "{% capture signature %}{{ data-to-sign | hmac_sha1_digest: secret-key }}{% endcapture %}"], "url": "https://eu-api.mimecast.com{{uri}}"})
}

resource "tines_agent" "get_url_logs_3" {
    name = "Get URL Logs"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"payload": {"payload": {"data": [{"scanResult": "all"}]}, "uri": "/api/ttp/url/get-logs"}, "send_payload_as_body": "false", "story": "{% story Mimecast STS %}"})
}

resource "tines_agent" "get_sender_policy_4" {
    name = "Get Sender Policy"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"payload": {"uri": "/api/policy/blockedsenders/get-policy"}, "send_payload_as_body": "false", "story": "{% story Mimecast STS %}"})
}

resource "tines_agent" "return_results_5" {
    name = "Return Results"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"mode": "message_only", "payload": "{{.query_mimecast | as_object }}"})
}

resource "tines_agent" "send_to_mimecast_without_payload_6" {
    name = "Send to Mimecast without payload"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"payload": {"uri": "/api/domain/get-provision-status"}, "send_payload_as_body": "false", "story": "{% story Mimecast STS %}"})
}

resource "tines_agent" "send_to_mimecast_with_data_payload_7" {
    name = "Send to Mimecast with data payload"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"payload": {"payload": {"data": [{"domain": "tines.dev"}]}, "uri": "/api/domain/get-provision-status"}, "send_payload_as_body": "false", "story": "{% story Mimecast STS %}"})
}

resource "tines_agent" "query_mimecast_8" {
    name = "Query Mimecast"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.return_results_5.id]
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": "MC {{ access-key }}:{{ signature | base64_encode }}", "x-mc-app-id": "{{ app-id }}", "x-mc-date": "{{ date }}", "x-mc-req-id": "{{ req-id }}"}, "method": "post", "payload": {"data": []}, "placeholders": ["{% capture uri %}{{.webhook_agent.uri}}{% endcapture %}", "{% capture app-id %}{% credential mimecast-app-id %}{% endcapture %}", "{% capture app-key %}{% credential mimecast-app-key %}{% endcapture %}", "{% capture access-key %}{% credential mimecast-access-key %}{% endcapture %}", "{% capture secret-key-cred %}{% credential mimecast-secret-key %}{% endcapture %}{% capture secret-key %}{{ secret-key-cred | base64_decode }}{% endcapture %}", "{% capture date %}{{ \u0027now\u0027 | date: \u0027%a, %e %b %Y %H:%M:%S %Z\u0027 }}{% endcapture %}", "{% capture req-id %}{% story_run_guid %}{% endcapture %}", "{% capture data-to-sign %}{{date}}:{{req-id}}:{{uri}}:{{app-key}}{% endcapture %}", "{% capture signature %}{{ data-to-sign | hmac_sha1_digest: secret-key }}{% endcapture %}"], "url": "https://eu-api.mimecast.com{{uri}}"})
}

resource "tines_agent" "webhook_agent_9" {
    name = "Webhook Agent"
    agent_type = "Agents::WebhookAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.trigger_if_no_data_payload_10.id, tines_agent.trigger_if_data_payload_11.id]
    agent_options = jsonencode({"secret": "058e74f6dba4b5b15ba965959c254819", "verbs": "get,post"})
}

resource "tines_agent" "trigger_if_no_data_payload_10" {
    name = "Trigger if No Data Payload"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.query_mimecast_8.id]
    agent_options = jsonencode({"rules": [{"path": "{{.webhook_agent.payload}}", "type": "regex", "value": "^$"}]})
}

resource "tines_agent" "trigger_if_data_payload_11" {
    name = "Trigger if Data Payload"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.query_mimecast_2.id]
    agent_options = jsonencode({"rules": [{"path": "{{.webhook_agent.payload}}", "type": "!regex", "value": "^$"}]})
}

resource "tines_agent" "find_groups_12" {
    name = "Find Groups"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"payload": {"uri": "/api/directory/find-groups"}, "send_payload_as_body": "false", "story": "{% story Mimecast STS %}"})
}

resource "tines_agent" "make_request_to_mimecast_without_a_payload_13" {
    name = "Make Request to Mimecast without a Payload"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"payload": {"uri": "/api/ttp/url/get-logs"}, "send_payload_as_body": "false", "story": "{% story Mimecast STS %}"})
}
