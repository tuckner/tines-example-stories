terraform {
    required_providers {
        tines = {
        source = "github.com/tuckner/tines"
        version = ">=0.0.15"
        }
    }
}

provider "tines" {}

resource "tines_story" "paging" {
    name = "Paging"
    team_id = var.team_id
    description = <<EOF
An example of how to loop and page through an API and then consolidate the results (which may be unnecessary). This example is unique because Notion does not provide:

- The number of pages available
- The number of items remaining

Because of those obstacles, this workflow will built a counter of number of pages seen to calculate the number of events that should be imploded (consolidated). Once the paging has been completed, the 'Final Count' event will emit and set the number of events that should be consolidated. By default, the limit will be 100 events to be consolidated if the final count is more than 100.
EOF
}

resource "tines_credential" "notion" {
    name = "notion"
    mode = "TEXT"
    value = "replaceme"
    team_id = var.team_id
}

resource "tines_agent" "search_in_notion_0" {
    name = "Search in Notion"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = tines_story.paging.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.more_pages_1.id, tines_agent.no_more_pages_2.id]
    position = {
      x = 603.0
      y = 322.0
    }
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": "Bearer {{ .CREDENTIAL.notion }}", "User-Agent": "Tines"}, "method": "post", "payload": {"filter": {"property": "object", "value": "page"}, "sort": {"direction": "ascending", "timestamp": "last_edited_time"}, "start_cursor": "{{ .counter.cursor }}"}, "url": "https://api.notion.com/v1/search/"})
}

resource "tines_agent" "more_pages_1" {
    name = "More Pages"
    agent_type = "Agents::TriggerAgent"
    story_id = tines_story.paging.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.counter_3.id]
    position = {
      x = 603.0
      y = 172.0
    }
    agent_options = jsonencode({"rules": [{"path": "{{ .search_in_notion.body.has_more }}", "type": "regex", "value": "true"}]})
}

resource "tines_agent" "no_more_pages_2" {
    name = "No More Pages"
    agent_type = "Agents::TriggerAgent"
    story_id = tines_story.paging.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.last_page_6.id, tines_agent.more_pages_8.id]
    position = {
      x = 393.0
      y = 172.0
    }
    agent_options = jsonencode({"emit_no_match": "true", "rules": [{"path": "{{ .search_in_notion.body.has_more }}", "type": "regex", "value": "false"}]})
}

resource "tines_agent" "counter_3" {
    name = "Counter"
    agent_type = "Agents::EventTransformationAgent"
    story_id = tines_story.paging.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.search_in_notion_0.id]
    position = {
      x = 603.0
      y = 247.0
    }
    agent_options = jsonencode({"mode": "message_only", "payload": {"count": "{{ counter.count | plus: 1 }}", "cursor": "{{ .search_in_notion.body.next_cursor }}"}})
}

resource "tines_agent" "search_in_notion_4" {
    name = "Search in Notion"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = tines_story.paging.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.more_pages_1.id, tines_agent.no_more_pages_2.id]
    position = {
      x = 453.0
      y = 82.0
    }
    agent_options = jsonencode({"content_type": "json", "headers": {"Authorization": "Bearer {{ .CREDENTIAL.notion }}", "User-Agent": "Tines"}, "method": "post", "payload": {"filter": {"property": "object", "value": "page"}, "sort": {"direction": "ascending", "timestamp": "last_edited_time"}}, "url": "https://api.notion.com/v1/search/"})
}

resource "tines_agent" "implode_results_5" {
    name = "Implode Results"
    agent_type = "Agents::EventTransformationAgent"
    story_id = tines_story.paging.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    position = {
      x = 393.0
      y = 397.0
    }
    agent_options = jsonencode({"guid_path": "{% story_run_guid %}", "mode": "implode", "size_path": "{{ .final_count.count | default: 100 }}"})
}

resource "tines_agent" "last_page_6" {
    name = "Last Page"
    agent_type = "Agents::TriggerAgent"
    story_id = tines_story.paging.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.final_count_7.id]
    position = {
      x = 198.0
      y = 247.0
    }
    agent_options = jsonencode({"rules": [{"path": "{{ .no_more_pages.rule_matched }}", "type": "regex", "value": "true"}]})
}

resource "tines_agent" "final_count_7" {
    name = "Final Count"
    agent_type = "Agents::EventTransformationAgent"
    story_id = tines_story.paging.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.implode_results_5.id]
    position = {
      x = 198.0
      y = 322.0
    }
    agent_options = jsonencode({"mode": "message_only", "payload": {"count": "{{ .counter.count }}"}})
}

resource "tines_agent" "more_pages_8" {
    name = "More Pages"
    agent_type = "Agents::TriggerAgent"
    story_id = tines_story.paging.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.implode_results_5.id]
    position = {
      x = 393.0
      y = 247.0
    }
    agent_options = jsonencode({"rules": [{"path": "{{ .no_more_pages.rule_matched }}", "type": "regex", "value": "false"}]})
}
