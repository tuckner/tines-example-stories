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

resource "tines_agent" "build_results_1" {
    name = "Build Results"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"mode": "message_only", "payload": {"TorNode": "", "abuse_ipdb": "", "apivoid_score": "", "greynoise": "new", "ip": "", "location": ", , ", "raw_vt": null, "talos_email_score": ""}})
}

resource "tines_agent" "search_for_ip_address_in_abuse_ipdb_2" {
    name = "Search for IP Address in Abuse IPDB"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.build_results.id]
    agent_options = jsonencode({"content_type": "json", "headers": {"key": ""}, "log_error_on_status": [], "method": "get", "payload": {"ipAddress": "", "maxAgeInDays": "90", "verbose": "true"}, "url": "https://api.abuseipdb.com/api/v2/check"})
}

resource "tines_agent" "get_ip_address_reputation_details_in_talos_intelligence_3" {
    name = "Get IP Address Reputation Details in Talos Intelligence"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.search_for_ip_address_in_virustotal.id]
    agent_options = jsonencode({"content_type": "json", "headers": {"Referer": "https://talosintelligence.com/reputation_center/lookup?search="}, "log_error_on_status": [], "method": "get", "payload": {"query": "/api/v2/details/ip/", "query_entry": ""}, "url": "https://talosintelligence.com/sb_api/query_lookup"})
}

resource "tines_agent" "webhook_agent_4" {
    name = "Webhook Agent"
    agent_type = "Agents::WebhookAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.lookup_ip_in_greynoise.id]
    agent_options = jsonencode({"secret": "f48aa7ff977c9adc1b48979ebabffeb1", "verbs": "get,post"})
}

resource "tines_agent" "test_using_me_-_analyze_ip_5" {
    name = "TEST USING ME - Analyze IP"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"payload": {"ipaddress": "83.141.10.10"}, "story": ""})
}

resource "tines_agent" "search_for_ip_address_in_virustotal_6" {
    name = "Search for IP Address in VirusTotal"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.check_ip_reputation_using_apivoid.id]
    agent_options = jsonencode({"log_error_on_status": [], "method": "get", "payload": {"apikey": "", "ip": ""}, "url": "https://www.virustotal.com/vtapi/v2/ip-address/report"})
}

resource "tines_agent" "lookup_ip_in_greynoise_7" {
    name = "Lookup IP in GreyNoise"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.get_tor_nodes.id]
    agent_options = jsonencode({"content_type": "json", "headers": {"key": ""}, "log_error_on_status": [], "method": "get", "payload": {}, "url": "https://api.greynoise.io/v2/noise/context/"})
}

resource "tines_agent" "check_ip_reputation_using_apivoid_8" {
    name = "Check IP Reputation using APIVoid"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.search_for_ip_address_in_abuse_ipdb.id]
    agent_options = jsonencode({"content_type": "json", "log_error_on_status": [], "method": "get", "payload": {"ip": "", "key": ""}, "url": "https://endpoint.apivoid.com/iprep/v1/pay-as-you-go/"})
}

resource "tines_agent" "trigger_if_tor_node_9" {
    name = "Trigger if Tor Node"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.get_ip_address_reputation_details_in_talos_intelligence.id]
    agent_options = jsonencode({"emit_no_match": "true", "rules": [{"path": "", "type": "regex", "value": ""}]})
}

resource "tines_agent" "get_tor_nodes_10" {
    name = "Get Tor Nodes"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.trigger_if_tor_node.id]
    agent_options = jsonencode({"content_type": "json", "log_error_on_status": [], "method": "get", "url": "https://check.torproject.org/cgi-bin/TorBulkExitList.py?ip="})
}
