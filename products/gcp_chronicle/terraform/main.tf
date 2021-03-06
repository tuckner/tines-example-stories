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

resource "tines_agent" "get_chronicle_recent_alerts_0" {
    name = "Get Chronicle Recent Alerts"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.explode_alerts_1.id]
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": "Bearer {{ .CREDENTIAL.chronicle }}"}, "method": "get", "payload": {"end_time": "{{ \"now\" | date: \"%Y-%m-%dT%H:%M:%SZ\" }}", "page_size": "100", "start_time": "{{ \"now\" | date: \u0027%s\u0027 | minus: 900 | date: \"%Y-%m-%dT%H:%M:%SZ\" }}"}, "url": "https://backstory.googleapis.com/v1/alert/listalerts"})
}

resource "tines_agent" "explode_alerts_1" {
    name = "Explode Alerts"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.explode_alert_info_9.id]
    agent_options = jsonencode({"mode": "explode", "path": "{{.get_chronicle_recent_alerts.body.alerts}}", "to": "alert"})
}

resource "tines_agent" "get_chronicle_events_for_asset_2" {
    name = "Get Chronicle Events for Asset"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": "Bearer {{ .CREDENTIAL.chronicle }}"}, "method": "get", "payload": {"asset.hostname": "elvira-hammett-pc", "end_time": "{{ \"now\" | date: \"%Y-%m-%dT%H:%M:%SZ\" }}", "page_size": "100", "reference_time": "{{ \"now\" | date: \u0027%s\u0027 | minus: 900 | date: \"%Y-%m-%dT%H:%M:%SZ\" }}", "start_time": "{{ \"now\" | date: \u0027%s\u0027 | minus: 900 | date: \"%Y-%m-%dT%H:%M:%SZ\" }}"}, "url": "https://backstory.googleapis.com/v1/asset/listevents"})
}

resource "tines_agent" "get_chronicle_ip_ioc_details_3" {
    name = "Get Chronicle IP IoC Details"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": "Bearer {{ .CREDENTIAL.chronicle }}"}, "method": "get", "payload": {"artifact.destination_ip_address": "1.1.1.1"}, "url": "https://backstory.googleapis.com/v1/artifact/listiocdetails"})
}

resource "tines_agent" "get_chronicle_domain_ioc_details_4" {
    name = "Get Chronicle Domain IoC Details"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": "Bearer {{ .CREDENTIAL.chronicle }}"}, "method": "get", "payload": {"artifact.domain_name": "google.com"}, "url": "https://backstory.googleapis.com/v1/artifact/listiocdetails"})
}

resource "tines_agent" "get_chronicle_iocs_5" {
    name = "Get Chronicle IoCs"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": "Bearer {{ .CREDENTIAL.chronicle }}"}, "method": "get", "payload": {"page_size": "100", "start_time": "{{ \"now\" | date: \u0027%s\u0027 | minus: 900 | date: \"%Y-%m-%dT%H:%M:%SZ\" }}"}, "url": "https://backstory.googleapis.com/v1/ioc/listiocs"})
}

resource "tines_agent" "get_chronicle_ip_access_asset_list_6" {
    name = "Get Chronicle IP Access Asset List"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": "Bearer {{ .CREDENTIAL.chronicle }}"}, "method": "get", "payload": {"artifact.destination_ip_address": "1.1.1.1", "end_time": "{{ \"now\" | date: \"%Y-%m-%dT%H:%M:%SZ\" }}", "page_size": "100", "start_time": "{{ \"now\" | date: \u0027%s\u0027 | minus: 900 | date: \"%Y-%m-%dT%H:%M:%SZ\" }}"}, "url": "https://backstory.googleapis.com/v1/artifact/listassets"})
}

resource "tines_agent" "get_chronicle_hash_access_asset_list_7" {
    name = "Get Chronicle Hash Access Asset List"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": "Bearer {{ .CREDENTIAL.chronicle }}"}, "method": "get", "payload": {"artifact.hash_sha1": "e41b9bcf1d02fd561cc28ab0b5e67e8d67f563bb", "end_time": "{{ \"now\" | date: \"%Y-%m-%dT%H:%M:%SZ\" }}", "page_size": "100", "start_time": "{{ \"now\" | date: \u0027%s\u0027 | minus: 900 | date: \"%Y-%m-%dT%H:%M:%SZ\" }}"}, "url": "https://backstory.googleapis.com/v1/artifact/listassets"})
}

resource "tines_agent" "get_chronicle_alerts_8" {
    name = "Get Chronicle Alerts"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": "Bearer {{ .CREDENTIAL.chronicle }}"}, "method": "get", "payload": {"end_time": "{{ \"now\" | date: \"%Y-%m-%dT%H:%M:%SZ\" }}", "page_size": "100", "start_time": "{{ \"now\" | date: \u0027%s\u0027 | minus: 900 | date: \"%Y-%m-%dT%H:%M:%SZ\" }}"}, "url": "https://backstory.googleapis.com/v1/alert/listalerts"})
}

resource "tines_agent" "explode_alert_info_9" {
    name = "Explode Alert Info"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.deduplicate_alerts_10.id]
    agent_options = jsonencode({"mode": "explode", "path": "{{.explode_alerts.alert.alertInfos }}", "to": "alertInfo"})
}

resource "tines_agent" "deduplicate_alerts_10" {
    name = "Deduplicate Alerts"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.create_issue_in_jira_11.id]
    agent_options = jsonencode({"emit_duplicate": "false", "mode": "deduplicate", "path": "{{.explode_alerts.alert.asset}}{{.explode_alert_info.alertInfo.name }}", "period": "86400"})
}

resource "tines_agent" "create_issue_in_jira_11" {
    name = "Create Issue in Jira"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"basic_auth": ["{{ .RESOURCE.jira_username }}", "{{ .CREDENTIAL.jira_api_token }}"], "content_type": "json", "method": "post", "payload": {"fields": {"description": "New alert for host: {{.explode_alerts.alert.asset.hostname | default: .explode_alerts.alert.asset.assetIpAddress }}\n\nLog entry:\n{code}\n{{.explode_alert_info.alertInfo.rawLog | base64_decode }}\n{code}\n\nChronicle Link:\n{{ .explode_alert_info.alertInfo.uri }}", "issuetype": {"name": "Task"}, "priority": {"name": "Highest"}, "project": {"key": "DEMO"}, "summary": "{{ .explode_alerts.alert.alertInfos.first.name }} ::: {{.explode_alerts.alert.asset.hostname | default: .explode_alerts.alert.asset.assetIpAddress }}"}}, "url": "https://{{ .RESOURCE.jira_url }}/rest/api/2/issue"})
}

resource "tines_agent" "get_chronicle_domain_access_asset_list_12" {
    name = "Get Chronicle Domain Access Asset List"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": "Bearer {{ .CREDENTIAL.chronicle }}"}, "method": "get", "payload": {"artifact.domain_name": "google.com", "end_time": "{{ \"now\" | date: \"%Y-%m-%dT%H:%M:%SZ\" }}", "page_size": "100", "start_time": "{{ \"now\" | date: \u0027%s\u0027 | minus: 900 | date: \"%Y-%m-%dT%H:%M:%SZ\" }}"}, "url": "https://backstory.googleapis.com/v1/artifact/listassets"})
}
