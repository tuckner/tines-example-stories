terraform {
    required_providers {
        tines = {
        source = "github.com/tuckner/tines"
        version = ">=0.0.15"
        }
    }
}

provider "tines" {}

resource "tines_story" "loops_with_counters" {
    name = "Loops With Counters"
    team_id = var.team_id
    description = <<EOF
Many job operations have consistent methods to break out of of the loop once a condition is met, however, there can be many instances where breaking out a loop prior to that condition makes more sense. In Tines, we can introduce a 'Counter' which the workflow can increment and use in order to break out of the loop on the chance that the condition being met isn't available in a timely manner.
EOF
}

resource "tines_agent" "trigger_if_complete_0" {
    name = "Trigger if Complete"
    agent_type = "Agents::TriggerAgent"
    story_id = tines_story.loops_with_counters.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.build_results_4.id]
    position = {
      x = 960.0
      y = 345.0
    }
    agent_options = jsonencode({"rules": [{"path": "{{.check_scan_status.body.state}}", "type": "regex", "value": "success"}]})
}

resource "tines_agent" "counter_more_than_20_1" {
    name = "Counter More Than 20"
    agent_type = "Agents::TriggerAgent"
    story_id = tines_story.loops_with_counters.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.build_results_4.id]
    position = {
      x = 945.0
      y = 495.0
    }
    agent_options = jsonencode({"rules": [{"path": "{{.increment_counter.counter}}", "type": "field\u003e=value", "value": "20"}]})
}

resource "tines_agent" "counter_less_than_20_2" {
    name = "Counter Less Than 20"
    agent_type = "Agents::TriggerAgent"
    story_id = tines_story.loops_with_counters.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.delay_event_8.id]
    position = {
      x = 561.0
      y = 501.0
    }
    agent_options = jsonencode({"rules": [{"path": "{{.increment_counter.counter}}", "type": "field\u003cvalue", "value": "20"}]})
}

resource "tines_agent" "trigger_if_in_queue_3" {
    name = "Trigger if IN Queue"
    agent_type = "Agents::TriggerAgent"
    story_id = tines_story.loops_with_counters.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.increment_counter_5.id]
    position = {
      x = 561.0
      y = 351.0
    }
    agent_options = jsonencode({"rules": [{"path": "{{.check_scan_status.body.state}}", "type": "regex", "value": "in_queue|in_progress"}]})
}

resource "tines_agent" "build_results_4" {
    name = "Build Results"
    agent_type = "Agents::EventTransformationAgent"
    story_id = tines_story.loops_with_counters.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    position = {
      x = 780.0
      y = 570.0
    }
    agent_options = jsonencode({"mode": "message_only", "payload": {"analysis_date": "{% if trigger_if_error.rule_matched%}error{% elsif counter_more_than_20.rule_matched%}timed out{% else %}{{.retrieve_scan_result.body.analysis_start_time}}{% endif %}", "analysis_link": "https://www.hybrid-analysis.com/sample/{{.retrieve_scan_result.body.sha256}}", "engine": "hybrid analysis", "file_name": "{{.webhook_agent.file_name}}", "malicious": "{% if retrieve_scan_result.body.verdict == \u0027malicious\u0027 or retrieve_scan_result.body.verdict == \u0027suspicious\u0027 %}true{% elsif trigger_if_error.rule_matched%}error{% elsif counter_more_than_20.rule_matched%}timed out{% else %}false{% endif %}", "new": "{% if trigger_if_file_exists.rule_matched %}false{% elsif trigger_if_error.rule_matched%}error{% else %}true{% endif %}"}})
}

resource "tines_agent" "increment_counter_5" {
    name = "Increment Counter"
    agent_type = "Agents::EventTransformationAgent"
    story_id = tines_story.loops_with_counters.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.counter_more_than_20_1.id, tines_agent.counter_less_than_20_2.id]
    position = {
      x = 561.0
      y = 426.0
    }
    agent_options = jsonencode({"mode": "message_only", "payload": {"counter": "{{.increment_counter.counter | plus: 1}}"}})
}

resource "tines_agent" "trigger_if_error_6" {
    name = "Trigger if Error"
    agent_type = "Agents::TriggerAgent"
    story_id = tines_story.loops_with_counters.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.build_results_4.id]
    position = {
      x = 780.0
      y = 345.0
    }
    agent_options = jsonencode({"rules": [{"path": "{{.check_scan_status.body.state}}", "type": "regex", "value": "Error"}]})
}

resource "tines_agent" "check_scan_status_7" {
    name = "Check Scan Status"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = tines_story.loops_with_counters.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.trigger_if_complete_0.id, tines_agent.trigger_if_in_queue_3.id, tines_agent.trigger_if_error_6.id]
    position = {
      x = 561.0
      y = 276.0
    }
    agent_options = jsonencode({"headers": {"api-key": "{% credential HybridAnalysisAPI %}"}, "log_error_on_status": [], "method": "get", "retry_on_status": ["429"], "url": "https://www.hybrid-analysis.com/api/v2/report/{{.upload_file_to_hybrid_analysis.body.job_id}}/state"})
}

resource "tines_agent" "delay_event_8" {
    name = "Delay Event"
    agent_type = "Agents::EventTransformationAgent"
    story_id = tines_story.loops_with_counters.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.check_scan_status_7.id]
    position = {
      x = 561.0
      y = 576.0
    }
    agent_options = jsonencode({"mode": "delay", "seconds": "60"})
}

resource "tines_agent" "upload_file_to_hybrid_analysis_9" {
    name = "Upload File to Hybrid Analysis"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = tines_story.loops_with_counters.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.check_scan_status_7.id]
    position = {
      x = 561.0
      y = 186.0
    }
    agent_options = jsonencode({"content_type": "data", "headers": {"api-key": "{% credential HybridAnalysisAPI %}"}, "log_error_on_status": [], "method": "post", "payload": {"allow_community_access": "false", "environment_id": "100", "file": {"contents": "{{.webhook_agent.base64_encoded_contents | base64_decode}}", "filename": "{{.webhook_agent.file_name}}"}}, "retry_on_status": ["429"], "url": "https://www.hybrid-analysis.com/api/v2/submit/file"})
}

resource "tines_annotation" "annotation_0" {
    story_id = tines_story.loops_with_counters.id
    content = <<EOF
Increment Counter

The 'Increment Counter' action will set a base integer value that will be increased by one each time it is trigger within the loop looking for a scan status of 'complete' from Hybrid Analysis.
EOF
    position = {
      x = 240.0
      y = 390.0
    }
}
