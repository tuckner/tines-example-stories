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

resource "tines_global_resource" "jarm_list" {
  name = "jarm_list"
  value_type = "array"
  value = "[]"
}

resource "tines_global_resource" "tines_email_resource" {
  name = "tines_email_resource"
  value_type = "text"
  value = var.tines_email
}

resource "tines_agent" "get_jarm_pastebin" {
    name = "Get JARM Pastebin"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.extract_ip_addresses_using_regex.id]
    agent_options = jsonencode({"url": "https://pastebin.com/raw/DzsPgH9w", "headers": {}, "method": "get", "content_type": "json"})
}

resource "tines_agent" "palo_alto_dynamic_blocklist" {
    name = "Palo Alto Dynamic Blocklist"
    agent_type = "Agents::WebhookAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = format(jsonencode({"secret": "71f890a9a64eb0cb5f98924291f13fc1", "verbs": "get,post", "response": "{{.RESOURCE.%s | join: \"\n\" }}"}), tines_global_resource.jarm_list.name)
}

resource "tines_agent" "extract_ip_addresses_using_regex" {
    name = "Extract IP Addresses Using Regex"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.append_values_to_a_global_resource.id]
    agent_options = jsonencode({"matchers": [{"path": "{{.get_jarm_pastebin.body}}", "to": "{{ \"ips\" | uniq }}", "regexp": "\\b(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\b"}], "mode": "extract"})
}

resource "tines_agent" "append_values_to_a_global_resource" {
    name = "Append Values to a Global Resource"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = format(jsonencode({"url": "https://{{ .RESOURCE.tines_domain }}/api/v1/global_resources/%s/", "headers": {"x-user-token": "{{ .CREDENTIAL.tines_user_token }}", "x-user-email": "{{ .RESOURCE.%s }}"}, "method": "put", "content_type": "json", "payload": {"value_type": "array", "value": "{{.extract_ip_addresses_using_regex.ips | as_object }}"}}), tines_global_resource.tines_email_resource.name, tines_global_resource.jarm_list.id)
}

