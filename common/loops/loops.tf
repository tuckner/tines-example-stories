terraform {
  required_providers {
    tines = {
      source = "github.com/tuckner/tines"
      version = ">=0.0.5"
    }
  }
}

provider "tines" {
  email    = var.tines_email
  base_url = var.tines_base_url
  token    = var.tines_token
}

resource "tines_agent" "get_hybrid_scan_results" {
    name = "Get hybrid scan results"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"url": "https://www.hybrid-analysis.com/api/v2/report/{{.submit_file_to_hybrid_analysis.body.job_id}}/summary", "headers": {"api-key": "{% credential Hybrid %}"}, "log_error_on_status": [], "method": "get", "user_agent": "Falcon Sandbox"})
}

resource "tines_agent" "hybrid_scan_not_in_progress_or_complete" {
    name = "Hybrid scan not in progress or complete"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"rules": [{"path": "{{.check_status_of_hybrid_file_scan.body.state}}", "type": "!regex", "value": "SUCCESS"}, {"path": "{{.check_status_of_hybrid_file_scan.body.state}}", "type": "!regex", "value": "IN_PROGRESS"}]})
}

resource "tines_agent" "hybrid_file_scan_still_in_progress" {
    name = "Hybrid file scan still in progress"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.delay_event.id]
    agent_options = jsonencode({"rules": [{"path": "{{.check_status_of_hybrid_file_scan.body.state}}", "type": "regex", "value": "IN_PROGRESS"}]})
}

resource "tines_agent" "delay_event" {
    name = "Delay Event"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.check_status_of_hybrid_file_scan.id]
    agent_options = jsonencode({"seconds": 30, "mode": "delay"})
}

resource "tines_agent" "hybrid_file_scan_complete" {
    name = "Hybrid file scan complete"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.get_hybrid_scan_results.id]
    agent_options = jsonencode({"rules": [{"path": "{{.check_status_of_hybrid_file_scan.body.state}}", "type": "regex", "value": "SUCCESS"}]})
}

resource "tines_agent" "check_status_of_hybrid_file_scan" {
    name = "Check status of hybrid file scan"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.hybrid_scan_not_in_progress_or_complete.id, tines_agent.hybrid_file_scan_still_in_progress.id, tines_agent.hybrid_file_scan_complete.id]
    agent_options = jsonencode({"url": "https://www.hybrid-analysis.com/api/v2/report/{{.submit_file_to_hybrid_analysis.body.job_id}}/state", "headers": {"api-key": "{% credential Hybrid %}"}, "log_error_on_status": [], "method": "get", "user_agent": "Falcon Sandbox"})
}

resource "tines_agent" "submit_file_to_hybrid_analysis" {
    name = "Submit file to Hybrid analysis"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.check_status_of_hybrid_file_scan.id]
    agent_options = jsonencode({"payload": {"environment_id": "110", "file": {"contents": "{{.explode_attachments.attachment.base64encodedcontents | base64_decode}}", "filename": "{{.explode_attachments.attachment.filename}}"}, "user-agent": "Falcon Sandbox"}, "url": "https://www.hybrid-analysis.com/api/v2/submit/file", "log_error_on_status": [], "headers": {"api-key": "{% credential Hybrid %}"}, "content_type": "data", "method": "post"})
}
