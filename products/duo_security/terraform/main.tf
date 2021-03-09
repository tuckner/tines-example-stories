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

resource "tines_global_resource" "duo_auth_integration_key" {
    name = "duo_auth_integration_key"
    value_type = "text"
    value = "replaceme"
}

resource "tines_global_resource" "duo_admin_integration_key" {
    name = "duo_admin_integration_key"
    value_type = "text"
    value = "replaceme"
}

resource "tines_global_resource" "duo_api_hostname" {
    name = "duo_api_hostname"
    value_type = "text"
    value = "replaceme"
}

resource "tines_agent" "send_alert_verification_push_in_duo_security_0" {
    name = "Send Alert Verification Push in Duo Security"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"payload": {"method": "POST", "params": {"device": "auto", "factor": "push", "type": "Alert Verification", "username": "{{ username }}"}, "path": "/auth/v2/auth"}, "send_payload_as_body": "false", "story": "{% story Duo Security %}"})
}

resource "tines_agent" "send_api_request_to_duo_security_1" {
    name = "Send API Request to Duo Security"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.exit_14.id]
    agent_options = jsonencode({"basic_auth": ["{% if receive_sts.path contains \u0027/admin/\u0027 %}{{.RESOURCE.duo_admin_integration_key }}{% else %}{{ .RESOURCE.duo_auth_integration_key }}{% endif %}", "{{ signature | hmac_sha1: duo-s-key }}"], "content_type": "{% if method == \u0027POST\u0027 %}form{% else %}json{% endif %}", "headers": {"Date": "{{ date }}"}, "method": "{{ method }}", "payload": "{{ .receive_sts.params | as_object }}", "placeholders": {"date": "{% assign date = \u0027now\u0027 | date: \u0027%a, %d %b %Y %T %z\u0027 %}", "duo-s-key": "{% capture duo-s-key %}{% if receive_sts.path contains \u0027/admin/\u0027 %}{{.CREDENTIAL.duo_admin_secret_key }}{% else %}{{ .CREDENTIAL.duo_auth_secret_key }}{% endif %}{% endcapture %}", "host": "{% capture host %}{{ .RESOURCE.duo_api_hostname }}{% endcapture %}", "method": "{% assign method = .receive_sts.method %}", "params": "{% capture params %}{% if .receive_sts.params %}{% for key in .receive_sts.params %}{{ key[0] }}={{ .receive_sts.params | get: key[0] | replace: \" \", \"%20\" }}{% if forloop.last == false %}\u0026{% endif %}{% endfor %}{% else %}{% endif%}{% endcapture %}{{ params }}", "path": "{% assign path = .receive_sts.path %}", "signature": "{% capture signature %}{{ date }}\n{{ method }}\n{{ host }}\n{{ path }}\n{{ params }}{% endcapture %}"}, "url": "https://{{ .RESOURCE.duo_api_hostname }}{{ .receive_sts.path }}"})
}

resource "tines_agent" "get_groups_in_duo_security_2" {
    name = "Get Groups in Duo Security"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"payload": {"method": "GET", "path": "/admin/v1/groups"}, "send_payload_as_body": "false", "story": "{% story Duo Security %}"})
}

resource "tines_agent" "get_u2f_tokens_in_duo_security_3" {
    name = "Get U2F Tokens in Duo Security"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"payload": {"method": "GET", "path": "/admin/v1/u2ftokens"}, "send_payload_as_body": "false", "story": "{% story Duo Security %}"})
}

resource "tines_agent" "receive_sts_4" {
    name = "Receive STS"
    agent_type = "Agents::WebhookAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.send_api_request_to_duo_security_1.id]
    agent_options = jsonencode({"include_headers": "false", "secret": "9532b594b834c192e8156ce7d44429ce", "verbs": "get,post"})
}

resource "tines_agent" "delay_event_5" {
    name = "Delay Event"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.get_alert_verification_push_status_in_duo_security_12.id]
    agent_options = jsonencode({"mode": "delay", "seconds": 10})
}

resource "tines_agent" "get_admin_logs_in_duo_security_6" {
    name = "Get Admin Logs in Duo Security"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"payload": {"method": "GET", "params": {"mintime": "{{ \u0027now\u0027 | date: \u0027%s\u0027 | minus: 10000 }}"}, "path": "/admin/v1/logs/administrator"}, "send_payload_as_body": "false", "story": "{% story Duo Security %}"})
}

resource "tines_agent" "get_phones_in_duo_security_7" {
    name = "Get Phones in Duo Security"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"payload": {"method": "GET", "path": "/admin/v1/phones"}, "send_payload_as_body": "false", "story": "{% story Duo Security %}"})
}

resource "tines_agent" "get_authentication_logs_in_duo_security_8" {
    name = "Get Authentication Logs in Duo Security"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"payload": {"method": "GET", "params": {"maxtime": "{{ \u0027now\u0027 | date: \u0027%s\u0027 }}000", "mintime": "{{ \u0027now\u0027 | date: \u0027%s\u0027 | minus: 10000 }}000"}, "path": "/admin/v2/logs/authentication"}, "send_payload_as_body": "false", "story": "{% story Duo Security %}"})
}

resource "tines_agent" "get_endpoints_in_duo_security_9" {
    name = "Get Endpoints in Duo Security"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"payload": {"method": "GET", "path": "/admin/v1/endpoints"}, "send_payload_as_body": "false", "story": "{% story Duo Security %}"})
}

resource "tines_agent" "get_hardware_tokens_in_duo_security_10" {
    name = "Get Hardware Tokens in Duo Security"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"payload": {"method": "GET", "path": "/admin/v1/tokens"}, "send_payload_as_body": "false", "story": "{% story Duo Security %}"})
}

resource "tines_agent" "send_alert_verification_push_async_in_duo_security_11" {
    name = "Send Alert Verification Push Async in Duo Security"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.delay_event_5.id]
    agent_options = jsonencode({"payload": {"method": "POST", "params": {"async": "1", "device": "auto", "factor": "push", "type": "Alert Verification", "username": "{{ username }}"}, "path": "/auth/v2/auth"}, "send_payload_as_body": "false", "story": "{% story Duo %}"})
}

resource "tines_agent" "get_alert_verification_push_status_in_duo_security_12" {
    name = "Get Alert Verification Push Status in Duo Security"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.if_waiting_15.id, tines_agent.if_allow_16.id, tines_agent.if_deny_17.id]
    agent_options = jsonencode({"payload": {"method": "GET", "params": {"txid": "{{ .send_alert_verification_push_async_in_duo_security.result.response.txid }}"}, "path": "/auth/v2/auth_status"}, "send_payload_as_body": "false", "story": "{% story Duo %}"})
}

resource "tines_agent" "get_users_in_duo_security_13" {
    name = "Get Users in Duo Security"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"payload": {"method": "GET", "path": "/admin/v1/users"}, "send_payload_as_body": "false", "story": "{% story Duo Security %}"})
}

resource "tines_agent" "exit_14" {
    name = "Exit"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"mode": "message_only", "payload": {"result": "{{ .send_api_request_to_duo_security.body | as_object }}"}})
}

resource "tines_agent" "if_waiting_15" {
    name = "If Waiting"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.delay_event_5.id]
    agent_options = jsonencode({"rules": [{"path": "{{ .get_alert_verification_push_status_in_duo_security.result.response.result }}", "type": "regex", "value": "waiting"}]})
}

resource "tines_agent" "if_allow_16" {
    name = "If Allow"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"rules": [{"path": "{{ .get_alert_verification_push_status_in_duo_security.result.response.result }}", "type": "regex", "value": "allow"}]})
}

resource "tines_agent" "if_deny_17" {
    name = "If Deny"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"rules": [{"path": "{{ .get_alert_verification_push_status_in_duo_security.result.response.result }}", "type": "regex", "value": "deny"}]})
}
