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

resource "tines_agent" "renew_subscription" {
    name = "Renew Subscription"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": "Bearer {% credential microsoft_graph %}"}, "log_error_on_status": [], "method": "patch", "payload": {"expirationDateTime": "{{ \"now\" | date: \"%s\" | plus: 240000 | date: \"%Y-%m-%dT%H:%M:%S.%H%M%d0Z\" }}"}, "url": "https://graph.microsoft.com/v1.0/subscriptions/{{ .RESOURCE.microsoft_graph_subscriptionid }}"})
}

resource "tines_agent" "create_json_from_dataframe" {
    name = "Create JSON from Dataframe"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.exit_sts.id]
    agent_options = jsonencode({"mode": "message_only", "payload": {"json": "{% assign keys = .query_loganalytics.body.tables[0] | jsonpath: \u0027$.columns[*].name\u0027 %}[{% for row in .query_loganalytics.body.tables[0].rows %}{ {% for data in row %} \"{{ keys[forloop.index0] }}\": \"{{ row[forloop.index0] | escape | strip_newlines }}\"{% if forloop.last == false %},{% endif %}{% endfor %}}{% if forloop.last == false %},{% endif %}{% endfor %}]"}})
}

resource "tines_agent" "query_loganalytics" {
    name = "Query LogAnalytics"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.create_json_from_dataframe.id]
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": "Bearer {{ .CREDENTIAL.microsoft_log_analytics }}"}, "method": "post", "payload": {"query": "{{ .receive_query.body.query }}"}, "url": "https://api.loganalytics.io/v1/workspaces/{{ .RESOURCE.microsoft_log_analytics_workspace}}/query"})
}

resource "tines_agent" "exit_sts" {
    name = "Exit STS"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"mode": "message_only", "payload": {"result": "{{ .create_json_from_dataframe.json | json_parse | as_object  }}"}})
}

resource "tines_agent" "create_threat_indicator_in_microsoft_graph" {
    name = "Create Threat Indicator in Microsoft Graph"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": "Bearer {{ .CREDENTIAL.microsoft_graph}}", "User-Agent": "Tines"}, "method": "post", "payload": {"action": "alert", "activityGroupNames": [], "confidence": 0, "description": "This is a canary indicator for demo purpose. Take no action on any observables set in this indicator.", "expirationDateTime": "2019-03-01T21:43:37.5031462+00:00", "externalId": "Test--8586509942679764298MS501", "fileHashType": "sha256", "fileHashValue": "aa64428647b57bf51524d1756b2ed746e5a3f31b67cf7fe5b5d8a9daf07ca314", "killChain": [], "malwareFamilyNames": [], "severity": 0, "tags": [], "targetProduct": "Azure Sentinel", "threatType": "WatchList", "tlpLevel": "green"}, "url": "https://graph.microsoft.com/beta/security/tiIndicators"})
}

resource "tines_agent" "retrieve_alerts_using_the_msgraph_security_api" {
    name = "Retrieve Alerts using the MSGraph Security API"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"headers": {"Authorization": "Bearer {{ .CREDENTIAL.msgraph }}"}, "method": "get", "url": "https://graph.microsoft.com/v1.0/security/alerts"})
}

resource "tines_agent" "check_for_alerts" {
    name = "Check for Alerts"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.explode_alerts.id]
    agent_options = jsonencode({"rules": [{"path": "{{ .receive_alerts.value }}", "type": "!regex", "value": "^$"}]})
}

resource "tines_agent" "receive_alerts" {
    name = "Receive Alerts"
    agent_type = "Agents::WebhookAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.check_for_alerts.id]
    agent_options = jsonencode({"include_headers": "false", "response": "{{.validationToken}}", "response_code": "200", "secret": "de9cb2b6f54dd6e008e53f5ec748caa3", "verbs": "get,post"})
}

resource "tines_agent" "explode_alerts" {
    name = "Explode Alerts"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.retrieve_alerts_using_the_msgraph_security_api.id]
    agent_options = jsonencode({"mode": "explode", "path": "{{.receive_alerts.value}}", "to": "alert"})
}

resource "tines_agent" "set_up_subscription" {
    name = "Set Up Subscription"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.create_a_text_global_resource.id]
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": "Bearer {% credential microsoft_graph %}"}, "log_error_on_status": [], "method": "post", "payload": {"changeType": "updated", "clientState": "SecretClientState", "expirationDateTime": "{{ \"now\" | date: \"%s\" | plus: 240000 | date: \"%Y-%m-%dT%H:%M:%S.%H%M%d0Z\" }}", "notificationUrl": "https://{{ .RESOURCE.tines_domain }}/webhook/830205ac2d7c6012581758b2aa70716c/de9cb2b6f54dd6e008e53f5ec748caa3", "resource": "security/alerts/?$filter=status eq \u0027NewAlert\u0027"}, "url": "https://graph.microsoft.com/v1.0/subscriptions"})
}

resource "tines_agent" "send_to_story_agent" {
    name = "Send to Story Agent"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"payload": {"query": "SecurityAlert | where TimeGenerated \u003e= ago(7d)"}, "story": "{% story Azure Sentinel Storyboard%}"})
}

resource "tines_agent" "receive_query" {
    name = "Receive Query"
    agent_type = "Agents::WebhookAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.query_loganalytics.id]
    agent_options = jsonencode({"secret": "75a96adec670533245038fd04274de2e", "verbs": "get,post"})
}

resource "tines_agent" "create_a_text_global_resource" {
    name = "Create a Text Global Resource"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"content_type": "json", "headers": {"x-user-email": "{{ .RESOURCE.tines_email }}", "x-user-token": "{{ .CREDENTIAL.tines_token }}"}, "method": "post", "payload": {"name": "microsoft_graph_subscriptionid", "team_id": "8", "value": "{{ .set_up_subscription.body.id }}", "value_type": "text"}, "url": "https://{{ .RESOURCE.tines_domain }}/api/v1/global_resources"})
}

resource "tines_agent" "delete_subscription" {
    name = "Delete Subscription"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": "Bearer {% credential microsoft_graph %}"}, "log_error_on_status": [], "method": "delete", "url": "https://graph.microsoft.com/v1.0/subscriptions/{{.RESOURCE.microsoft_graph_subscriptionid }}"})
}

resource "tines_agent" "authenticate_to_loganalytics" {
    name = "Authenticate to LogAnalytics"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"content-type": "form", "headers": {"user-agent": "Tines"}, "method": "post", "payload": {"client_id": "{{ client_id }}", "client_secret": "{{ client_secret }}", "grant_type": "client_credentials", "resource": "https://api.loganalytics.io"}, "url": "https://login.microsoftonline.com/{{ azure_tenant_id }}/oauth2/token"})
}
