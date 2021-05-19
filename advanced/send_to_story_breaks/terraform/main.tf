terraform {
    required_providers {
        tines = {
        source = "github.com/tuckner/tines"
        version = ">=0.0.15"
        }
    }
}

provider "tines" {}

resource "tines_story" "send_to_story_breaks" {
    name = "Send to Story Breaks"
    team_id = var.team_id
    description = <<EOF
There are some times when a complex child story needs to be broken out of a single flow, but ultimately should return to the parent story. This is an incredibly advanced 'feature', but does hold some use.

The key funtionality elements of Send to Story (Webhooks, 'agent_id', 'event_id', and Event Transforms) can be leveraged in unique ways to get this result.

In this flow, we will trigger a Send to Story which will send an event to a webhook 'Entry'. That webhook will receive a 'agent_id' and 'event_id' of the Send to Story action which the sub-flow should return to. We can utilize these pieces of information by including them in the 'Send to Continuance Webhook' HTTP Request Action that begins a new event flow in the third column.

The 'Continuance' flow receives the 'agent_id' and 'event_id' of the inital Send to Story call. In order for an action to return an event to a Send to Story action, two things must be true:

1. The first event (very important) of the flow must have 'agent_id' and 'event_id' keys. The action generating the first event of the chain does not need to be a Webhook but could be an Event Transform Action with the same name of the webhook immediately after which will overwrite the first event.
2. An Event Transform Action in message only mode and selected as an exit action in the Send to Story configuration.

With this example, you can see how complex paths can arrive back to a single Send to Story action even with breaks in the event chains.
EOF
}

resource "tines_agent" "start_here_0" {
    name = "Start Here"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = tines_story.send_to_story_breaks.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.send_to_story_agent_5.id]
    position = {
      x = 105.0
      y = 105.0
    }
    agent_options = jsonencode({"content_type": "json", "headers": {}, "method": "post", "payload": {"key": "value", "something": "the event contained {{ .somekey }}"}, "url": "http://www.example.com"})
}

resource "tines_agent" "send_to_continuance_webhook_1" {
    name = "Send to Continuance Webhook"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = tines_story.send_to_story_breaks.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    position = {
      x = 315.0
      y = 195.0
    }
    agent_options = jsonencode({"content_type": "json", "headers": {}, "method": "post", "payload": {"#agent_id": "{{.entry.[\u0027#agent_id\u0027] | as_object}}", "#event_id": "{{.entry.[\u0027#event_id\u0027] | as_object }}", "body": "{{.entry.body | as_object }}"}, "url": "https://quiet-vista-5142.tines.io/webhook/50b5181d44623742457fd81f189d9bbc/95c478c2a145a65d5342cb13f0f597ea"})
}

resource "tines_agent" "continuance_2" {
    name = "Continuance"
    agent_type = "Agents::WebhookAgent"
    story_id = tines_story.send_to_story_breaks.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.exit_3.id]
    position = {
      x = 540.0
      y = 105.0
    }
    agent_options = jsonencode({"include_headers": "false", "secret": "95c478c2a145a65d5342cb13f0f597ea", "verbs": "get,post"})
}

resource "tines_agent" "exit_3" {
    name = "Exit"
    agent_type = "Agents::EventTransformationAgent"
    story_id = tines_story.send_to_story_breaks.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    position = {
      x = 540.0
      y = 195.0
    }
    agent_options = jsonencode({"mode": "message_only", "payload": {"message": "This is an automatically generated message from Tines"}})
}

resource "tines_agent" "entry_4" {
    name = "Entry"
    agent_type = "Agents::WebhookAgent"
    story_id = tines_story.send_to_story_breaks.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.send_to_continuance_webhook_1.id]
    position = {
      x = 315.0
      y = 105.0
    }
    agent_options = jsonencode({"secret": "7ca0677db2794ee63939552bbdc62637", "verbs": "get,post"})
}

resource "tines_agent" "send_to_story_agent_5" {
    name = "Send to Story Agent"
    agent_type = "Agents::SendToStoryAgent"
    story_id = tines_story.send_to_story_breaks.id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    position = {
      x = 105.0
      y = 195.0
    }
    agent_options = jsonencode({"payload": {"key": "value", "something": "the event contained {{ .somekey }}"}, "story": "{{ .STORY.send_to_story_breaks }}"})
}

resource "tines_annotation" "annotation_0" {
    story_id = tines_story.send_to_story_breaks.id
    content = <<EOF
Example

Run the 'Start Here' action to trigger an event which will run the Send to Story. In order for this to work, the Send to Story needs an action beforehand in order to register 'agent_id' and 'event_id'.
EOF
    position = {
      x = -195.0
      y = 105.0
    }
}

resource "tines_annotation" "annotation_1" {
    story_id = tines_story.send_to_story_breaks.id
    content = <<EOF
Continuance

The HTTP request will provide the 'agent_id' and 'event_id' fields from the entry webhook which the Event Transform needs to use to return an event back to the Send to Story.
EOF
    position = {
      x = 735.0
      y = 120.0
    }
}
