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

resource "tines_agent" "get_gsuite_auth_token_0" {
    name = "Get GSuite Auth Token"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.get_emails_1.id]
    agent_options = jsonencode({"content_type": "form", "method": "post", "payload": {"assertion": "{% credential gsuite %}", "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer"}, "url": "https://www.googleapis.com/oauth2/v4/token"})
}

resource "tines_agent" "get_emails_1" {
    name = "Get Emails"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.explode_emails_3.id]
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": "Bearer {{.get_gsuite_auth_token.body.access_token}}"}, "method": "get", "payload": {"q": "in:inbox after:{{ \"now\" | date: \"%s\" | minus: 180 }}"}, "url": "https://www.googleapis.com/gmail/v1/users/me/messages"})
}

resource "tines_agent" "dedupe_emails_2" {
    name = "Dedupe Emails"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.get_email_by_id_4.id]
    agent_options = jsonencode({"lookback": "100", "mode": "deduplicate", "path": "{{.explode_emails.email.id}}{{.get_emails.message_id}}"})
}

resource "tines_agent" "explode_emails_3" {
    name = "Explode Emails"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.dedupe_emails_2.id]
    agent_options = jsonencode({"mode": "explode", "path": "{{.get_emails.body.messages}}", "to": "email"})
}

resource "tines_agent" "get_email_by_id_4" {
    name = "Get Email by ID"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.read_email_5.id]
    agent_options = jsonencode({"headers": {"Authorization": "Bearer {{.get_gsuite_auth_token.body.access_token}}"}, "method": "get", "payload": {"format": "raw"}, "url": "https://www.googleapis.com/gmail/v1/users/{{ email_address }}/messages/{{.explode_emails.email.id}}"})
}

resource "tines_agent" "read_email_5" {
    name = "Read Email"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"mode": "message_only", "payload": {"email": "{{.get_email_by_id.body.raw | base64url_decode | eml_parse | as_object }}"}})
}
