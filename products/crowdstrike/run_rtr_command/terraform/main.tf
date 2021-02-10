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

resource "tines_agent" "receive_command_0" {
    name = "Receive Command"
    agent_type = "Agents::WebhookAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.start_an_rtr_session_in_crowdstrike_falcon_17.id]
    agent_options = jsonencode({"secret": "49858c543d856826b8b5f695dbbdff06", "verbs": "get,post"})
}

resource "tines_agent" "send_to_story_agent_1" {
    name = "Send to Story Agent"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.parse_response_7.id]
    agent_options = jsonencode({"payload": {"command": "runscript -CloudFile=\"extract-scheduled-tasks.ps1\" -CommandLine=\"\"", "device_id": "50b29185696d4ea1aa465e4609b9b751"}, "story": "{% story Crowdstrike - Run RTR Command %}"})
}

resource "tines_agent" "delay_5_seconds_2" {
    name = "Delay 5 Seconds"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.increment_counter_4.id]
    agent_options = jsonencode({"mode": "delay", "seconds": 5})
}

resource "tines_agent" "execute_rtr_command_3" {
    name = "Execute RTR Command"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.check_status_and_retrieve_results_of_an_active_responder_rtr_command_14.id]
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": "Bearer {{.CREDENTIAL.crowdstrike}}"}, "method": "post", "payload": {"base_command": "{% assign base = .receive_command.body.command | split: \" \" %}{{base[0]}}", "command_string": "{{.receive_command.body.command}}", "session_id": "{{.start_an_rtr_session_in_crowdstrike_falcon.body.resources.first.session_id}}"}, "retry_on_status": ["429"], "url": "https://api.{{.RESOURCE.crowdstrike_domain}}/real-time-response/entities/active-responder-command/v1"})
}

resource "tines_agent" "increment_counter_4" {
    name = "Increment Counter"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.check_status_and_retrieve_results_of_an_active_responder_rtr_command_14.id]
    agent_options = jsonencode({"mode": "message_only", "payload": {"counter": "{{.increment_counter.counter | plus: 1}}"}})
}

resource "tines_agent" "get_chrome_extensions_5" {
    name = "Get Chrome Extensions"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.parse_response_16.id]
    agent_options = jsonencode({"payload": {"command": "runscript -CloudFile=\"tines_extract_chrome_extensions_from_endpoint\" -CommandLine=\"\"", "device_id": "cc0904730de3470eb5570c5f648f6716"}, "story": "{% story Crowdstrike - Run RTR Command %}"})
}

resource "tines_agent" "show_pop_up_message_6" {
    name = "Show Pop Up Message"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"payload": {"command": "runscript -CloudFile=\"tines_show_pop_up_message_on_endpoint\" -CommandLine=\"hello\"", "device_id": "cc0904730de3470eb5570c5f648f6716"}, "story": "{% story Crowdstrike - Run RTR Command %}"})
}

resource "tines_agent" "parse_response_7" {
    name = "Parse Response"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.explode_an_array_12.id]
    agent_options = jsonencode({"mode": "message_only", "payload": {"message": "{{.send_to_story_agent.result.stdout | json_parse | as_object}}"}})
}

resource "tines_agent" "trigger_if_error_8" {
    name = "Trigger if Error"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.delete_an_rtr_session_in_crowdstrike_falcon_15.id]
    agent_options = jsonencode({"rules": [{"path": "{{.execute_rtr_command.status}} {{.start_an_rtr_session_in_crowdstrike_falcon.status}} {{.check_status_and_retrieve_results_of_an_active_responder_rtr_command.status}}", "type": "regex", "value": "400|404|403"}]})
}

resource "tines_agent" "query_complete_9" {
    name = "Query Complete"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.delete_an_rtr_session_in_crowdstrike_falcon_15.id]
    agent_options = jsonencode({"rules": [{"path": "{{.check_status_and_retrieve_results_of_an_active_responder_rtr_command.body.resources.first.complete}}", "type": "field==value", "value": "true"}]})
}

resource "tines_agent" "query_not_complete_10" {
    name = "Query Not Complete"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.delay_5_seconds_2.id]
    agent_options = jsonencode({"rules": [{"path": "{{.check_status_and_retrieve_results_of_an_active_responder_rtr_command.body.resources.first.complete}}", "type": "field==value", "value": "false"}]})
}

resource "tines_agent" "build_results_11" {
    name = "Build Results"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"mode": "message_only", "payload": {"error": "{% if .start_an_rtr_session_in_crowdstrike_falcon.status != 201 %}Error Starting RTR Session - {{.start_an_rtr_session_in_crowdstrike_falcon.body.errors.first.message}}{% elsif .execute_rtr_command.status != 201 %}Error Executing Command on Device - {{.execute_rtr_command.body.errors.first.message}}{% elsif .check_status_and_retrieve_results_of_an_active_responder_rtr_command.status != 200 %}Error running script - {{.check_status_and_retrieve_results_of_an_active_responder_rtr_command.body.errors.first.message}}{% else %}No errors found when executing command {% endif %}", "query_successful": "{% if trigger_if_error %}false{% else %}true{% endif %}", "result": "{{.check_status_and_retrieve_results_of_an_active_responder_rtr_command.body.resources.first | default: \u0027Error - no results available\u0027 | as_object}}", "session_closed": "{% if .delete_an_rtr_session_in_crowdstrike_falcon.status == 204 %}true{% else %}false{% endif %}"}})
}

resource "tines_agent" "explode_an_array_12" {
    name = "Explode an Array"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"mode": "explode", "path": "{{.parse_response.message}}", "to": "individual_record"})
}

resource "tines_agent" "explode_extensions_13" {
    name = "Explode extensions"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"mode": "explode", "path": "{{.parse_response.message}}", "to": "extension"})
}

resource "tines_agent" "check_status_and_retrieve_results_of_an_active_responder_rtr_command_14" {
    name = "Check Status and Retrieve Results of an Active Responder RTR Command"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.trigger_if_error_8.id, tines_agent.query_complete_9.id, tines_agent.query_not_complete_10.id]
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": "Bearer {{.CREDENTIAL.crowdstrike}}"}, "method": "get", "payload": {"cloud_request_id": "{{.execute_rtr_command.body.resources.first.cloud_request_id}}", "sequence_id": "{{.increment_count.counter | default: 0}}"}, "retry_on_status": ["429"], "url": "https://api.{{.RESOURCE.crowdstrike_domain}}/real-time-response/entities/active-responder-command/v1"})
}

resource "tines_agent" "delete_an_rtr_session_in_crowdstrike_falcon_15" {
    name = "Delete an RTR Session in Crowdstrike Falcon"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.build_results_11.id]
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": "Bearer {{.CREDENTIAL.crowdstrike}}"}, "method": "delete", "payload": {"session_id": "{{.start_an_rtr_session_in_crowdstrike_falcon.body.resources.first.session_id}}"}, "retry_on_status": ["429"], "url": "https://api.{{.RESOURCE.crowdstrike_domain}}/real-time-response/entities/sessions/v1"})
}

resource "tines_agent" "parse_response_16" {
    name = "Parse Response"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.explode_extensions_13.id]
    agent_options = jsonencode({"mode": "message_only", "payload": {"message": "{{.get_chrome_extensions.result.stdout | json_parse | as_object}}"}})
}

resource "tines_agent" "start_an_rtr_session_in_crowdstrike_falcon_17" {
    name = "Start an RTR Session in Crowdstrike Falcon"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.execute_rtr_command_3.id]
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": "Bearer {{.CREDENTIAL.crowdstrike}}"}, "method": "post", "payload": {"device_id": "{{.receive_command.body.device_id}}", "origin": "string", "queue_offline": true}, "retry_on_status": ["429"], "url": "https://api.{{.RESOURCE.crowdstrike_domain}}/real-time-response/entities/sessions/v1"})
}
