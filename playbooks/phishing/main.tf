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

resource "tines_agent" "search_siem_for_visits_to_domain" {
    name = "Search SIEM for Visits to Domain"
    agent_type = "Agents::SendToStoryAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.explode_results.id]
    agent_options = jsonencode({"story": "{% story [Example] STS Search Splunk %}", "payload": {"search": "search source=proxy host=webproxy sourcetype=Bluecoat {{.extract_domain.domain.first.first}}  s_ip=* | table s_ip _time  c_ip cs_host cs_method cs_uri_path sc_status cs_Referer cs_User_Agent  _raw"}, "send_payload_as_body": "false"})
}

resource "tines_agent" "create_service_now_ticket" {
    name = "Create Service Now Ticket"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.search_siem_for_visits_to_domain.id, tines_agent.update_service_now_ticket.id]
    agent_options = jsonencode({"url": "https://{% global_resource demo_servicenow_fqdn %}/api/now/v1/table/incident", "basic_auth": "admin:{% credential servicenow %}", "log_error_on_status": [], "method": "post", "content_type": "json", "payload": {"short_description": "New Malicious Domain Detected on {{.extract_domain.domain[0]}}", "comments": "[code] An email sent to report-phishing@tines.xyz was detected as malicious. <br> The email was sent from {{.check_inbox.from}} with the subject <i>{{.check_inbox.subject}}</i>. <br><br>[/code][code]<pre><code>{{.check_inbox.body | newline_to_br }}\n}</code></pre>[/code][code]<br> The malicious URL in question is {{.explode_urls.url | replace: \".\", \"[.]\" | replace: \"http\", \"hxxp\"}}. <br><br> To view more details about the detection, please visit <a href=\"{{.submit_to_vt.body.permalink}}\">VirusTotal</a > The virustotal score was: {{.submit_to_vt.body.positives}} <br><br>   The domain is currently being searched for across our Firewall logs. If any results are found this ticket will be updated automatically.  {% story_run_link  %}[/code]"}})
}

resource "tines_agent" "update_service_now_victim_found" {
    name = "Update Service Now Victim Found"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.trigger_to_isolate_asset.id]
    agent_options = jsonencode({"url": "https://{% global_resource demo_servicenow_fqdn %}/api/now/v1/table/incident/{{.create_service_now_ticket.body.result.sys_id}}?sysparm_exclude_ref_link=true", "payload": {"comments": "[code] One person was found to have hit the domain. <br><br>  <b>Victim Data: </b><br>    Name: Thomas, <br>  Asset ID: {{.get_dhcp_search_results.body.results.result.field[0].value.text}},<br>   User Email: thomas@tines.io<br>  Location: {{.get_asset_owner.body.issues[0].fields.assignee.timeZone}} <br> <br>   They have been logged out of their account and their account has been locked. <br><br><b>Prompt Actions</b> <br>To isolate this asset in Carbon Black please click <a href=\"{% prompt isolate_asset %}\">here</a>.[/code]"}, "method": "put", "content_type": "json", "basic_auth": "admin:{% credential servicenow %}"})
}

resource "tines_agent" "update_service_now_sender_reply" {
    name = "Update Service Now Sender Reply"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"url": "https://{% global_resource demo_servicenow_fqdn %}/api/now/v1/table/incident/{{.create_service_now_ticket.body.result.sys_id}}?sysparm_exclude_ref_link=true", "payload": {"comments": "[code] Email sent to Sender {{.check_inbox.from}}: <br><br> Thanks for reporting the mail with the subject {{.check_inbox.subject}} to report-phishing@tines.xyx. As you suspected, this was indeed malicious. Please let us know if you engaged with any of the content in the email (clicked on any of the links, downloaded any of the attachments) - we'll be able to help secure your account immediately. Your report helps keep all of Tines safe - keep up the good work! [/code]"}, "method": "put", "content_type": "json", "basic_auth": "admin:{% credential servicenow %}"})
}

resource "tines_agent" "dhcp_search_complete" {
    name = "DHCP search complete"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.get_dhcp_search_results.id]
    agent_options = jsonencode({"rules": [{"path": "{{.get_dhcp_search_status.body.entry[0].content.dispatchState}}", "type": "regex", "value": "DONE"}]})
}

resource "tines_agent" "email_confirmation_to_sender" {
    name = "Email Confirmation to Sender"
    agent_type = "Agents::EmailAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.update_service_now_sender_reply.id]
    agent_options = jsonencode({"body": "Hi! <br><br>  Thanks for reporting the mail with the subject <i>{{.check_inbox.subject}} </i>to report-phishing@tines.xyx.<br><br> As you suspected, this email did indeed contain dangerous content and your report helps keep all of Tines safe - keep up the good work! <br><br> Please let us know if you engaged with any of the content in the email (clicked on any of the links, or downloaded any of the attachments) - we'll be able to help secure your account immediately.   <br><br>Thanks again,  <br><br>Tines Security Team", "recipients": "{{.check_inbox.from}}", "subject": "Thank you for Reporting "})
}

resource "tines_agent" "get_dhcp_search_status" {
    name = "Get DHCP search status"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.dhcp_search_complete.id]
    agent_options = jsonencode({"url": "https://spk.tines.xyz:8089/services/search/jobs/{{.get_host_from_dhcp_logs_single_result.body.sid}}{{.get_host_from_dhcp_logs_multiple_results.body.sid}}?output_mode=json", "log_error_on_status": [], "method": "get", "content_type": "json", "disable_ssl_verification": "true"})
}

resource "tines_agent" "get_dhcp_search_results" {
    name = "Get DHCP search results"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.found_matching_host.id]
    agent_options = jsonencode({"url": "https://spk.tines.xyz:8089/services/search/jobs/{{.get_host_from_dhcp_logs_single_result.body.sid}}{{.get_host_from_dhcp_logs_multiple_results.body.sid}}/results/", "log_error_on_status": [], "method": "get", "content_type": "json", "disable_ssl_verification": "true"})
}

resource "tines_agent" "check_inbox" {
    name = "Check Inbox"
    agent_type = "Agents::IMAPAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.explode_attachments.id, tines_agent.extract_urls.id]
    agent_options = jsonencode({"username": "report-phishing@tines.xyz", "folders": ["INBOX"], "emit_headers": "true", "ssl": true, "host": "box.tines.xyz", "password": "{% credential report-phishing-imap %}", "conditions": {}})
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

resource "tines_agent" "block_domain_in_cisco_umbrella" {
    name = "Block Domain in Cisco Umbrella"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.update_service_now_domain_blocked.id]
    agent_options = jsonencode({"url": "https://s-platform.api.opendns.com/1.0/events?customerKey={% credential umbrella %}", "log_error_on_status": [], "method": "post", "content_type": "json", "payload": {"dstUrl": "https://{{.extract_domain.domain}}/", "providerName": "Security Platform", "dstDomain": "{{.extract_domain.domain}}", "eventTime": "2019-02-08T09:30:26.0Z", "alertTime": "2019-02-08T11:14:26.0Z", "deviceId": "ba6a59f4-e692-4724-ba36-c28132c761de", "protocolVersion": "1.0a", "deviceVersion": "13.7a"}})
}

resource "tines_agent" "get_asset_owner" {
    name = "Get asset owner"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.log_out_victim.id]
    agent_options = jsonencode({"payload": {"jql": "project=AM AND 'Asset ID' ~ {{.get_dhcp_search_results.body.results.result.field[0].value.text}}"}, "url": "https://{% global_resource jira_domain %}/rest/api/2/search", "basic_auth": ["{% global_resource jira_svc_user %}", "{% credential jira_svc_pwd %}"], "log_error_on_status": [], "content_type": "json", "method": "post"})
}

resource "tines_agent" "found_matching_host" {
    name = "Found matching host"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.get_onelogin_cred.id]
    agent_options = jsonencode({"rules": [{"path": "{{.get_dhcp_search_status.body.entry[0].content.eventCount}}", "type": "field>value", "value": "0"}, {"path": "{{.get_dhcp_search_results.status}}", "type": "field==value", "value": "200"}]})
}

resource "tines_agent" "get_onelogin_cred" {
    name = "Get OneLogin Cred"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.get_asset_owner.id]
    agent_options = jsonencode({"payload": {"grant_type": "client_credentials"}, "url": "https://api.us.onelogin.com/auth/oauth2/token", "log_error_on_status": [], "headers": {"Authorization": "client_id:{% credential onelogin_client_id %}"}, "content_type": "json", "method": "post"})
}

resource "tines_agent" "log_out_victim" {
    name = "Log out victim"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.lock_victim_account.id]
    agent_options = jsonencode({"payload": {"status": "3"}, "url": "https://api.us.onelogin.com/api/1/users/{{.get_victim_details.body.data[0].id}}{{.find_additional_user_details.body.data[0].id}}", "log_error_on_status": [], "headers": {"authorization": "bearer:{{.get_onelogin_cred.body.data.first.access_token}}"}, "content_type": "json", "method": "put"})
}

resource "tines_agent" "prompt_received_to_reply_to_sender" {
    name = "Prompt Received to Reply to Sender"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.email_confirmation_to_sender.id]
    agent_options = jsonencode({"rules": [{"path": "{{.update_service_now_ticket.prompt.status}}", "type": "regex", "value": "confirm_malicious"}]})
}

resource "tines_agent" "extract_domain" {
    name = "Extract domain"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.create_service_now_ticket.id]
    agent_options = jsonencode({"matchers": [{"path": "{{.explode_urls.url}}", "to": "domain", "regexp": "^(?:https?:\\/\\/)?(?:[^@\\n]+@)?(?:www\\.)?([^:\\/\\n?]+)"}], "mode": "extract"})
}

resource "tines_agent" "update_service_now_domain_blocked" {
    name = "Update Service Now Domain Blocked"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"url": "https://{% global_resource demo_servicenow_fqdn %}/api/now/v1/table/incident/{{.create_service_now_ticket.body.result.sys_id}}?sysparm_exclude_ref_link=true", "payload": {"comments": "Domain {{.extract_domain.domain}} has been blocked in Cisco Umbrella"}, "method": "put", "content_type": "json", "basic_auth": "admin:{% credential servicenow %}"})
}

resource "tines_agent" "update_service_now_host_isolated" {
    name = "Update Service Now Host Isolated"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = []
    agent_options = jsonencode({"url": "https://{% global_resource demo_servicenow_fqdn %}/api/now/v1/table/incident/{{.create_service_now_ticket.body.result.sys_id}}?sysparm_exclude_ref_link=true", "payload": {"comments": "[code] Host {{.get_dhcp_search_results.body.results.result.field[0].value.text}} has been isolated in Carbon Black. <br> Sensor Group: {{.find_carbon_black_asset_by_hostname.body.first.group_id}} <br> OS Type: {{.find_carbon_black_asset_by_hostname.body.first.os_type}}:{{.find_carbon_black_asset_by_hostname.body.first.os_environment_display_string}}. [/code]"}, "method": "put", "content_type": "json", "basic_auth": "admin:{% credential servicenow %}"})
}

resource "tines_agent" "update_service_now_ticket" {
    name = "Update Service Now Ticket"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.prompt_received_to_reply_to_sender.id, tines_agent.prompt_received_to_block_domain.id]
    agent_options = jsonencode({"url": "https://{% global_resource demo_servicenow_fqdn %}/api/now/v1/table/incident/{{.create_service_now_ticket.body.result.sys_id}}?sysparm_exclude_ref_link=true", "basic_auth": "admin:{% credential servicenow %}", "log_error_on_status": [], "method": "put", "content_type": "json", "payload": {"comments": "[code] <b>Prompt Actions</b> <br>To respond to the reporter confirming to them that the email was malicious, please click <a href=\"{% prompt confirm_malicious %}\">here</a> <br>  To block the domain in Cisco Umbrella please click <a href=\"{% prompt block_domain %}\">here</a>.<br>  [/code]"}})
}

resource "tines_agent" "submit_to_vt" {
    name = "Submit to VT"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.url_is_malicious.id]
    agent_options = jsonencode({"url": "https://www.virustotal.com/vtapi/v2/url/report", "retry_on_status": ["429"], "method": "get", "payload": {"apikey": "{% credential virustotal %}", "resource": "{{.explode_urls.url}}"}})
}

resource "tines_agent" "prompt_received_to_block_domain" {
    name = "Prompt Received to Block Domain"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.block_domain_in_cisco_umbrella.id]
    agent_options = jsonencode({"rules": [{"path": "{{.update_service_now_ticket.prompt.status}}", "type": "regex", "value": "block_domain"}]})
}

resource "tines_agent" "explode_results" {
    name = "Explode Results"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.get_host_from_dhcp_logs_multiple_results.id]
    agent_options = jsonencode({"path": "{{.search_siem_for_visits_to_domain.results}}", "mode": "explode", "to": "result"})
}

resource "tines_agent" "get_host_from_dhcp_logs_multiple_results" {
    name = "Get host from DHCP logs multiple results"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.get_dhcp_search_status.id]
    agent_options = jsonencode({"payload": {"earliest_time": "{{.explode_results.result._time | date: '%s' | minus: 43200 | as_object}}", "search": "search host=dhcp \"IP Address\"={{.explode_results.result.s_ip}} (Description=New OR Description=Renew) | head 1 | fields \"Host Name\"", "latest_time": "{{.explode_results.result._time| date: '%s'}}", "output_mode": "json"}, "url": "https://spk.tines.xyz:8089/services/search/jobs", "log_error_on_status": [], "content_type": "form", "disable_ssl_verification": "true", "method": "post"})
}

resource "tines_agent" "contact_victim" {
    name = "Contact victim"
    agent_type = "Agents::EmailAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.user_confirmed_interaction_with_malicious_email.id]
    agent_options = jsonencode({"body": "Hi {{.get_victim_details.body.data[0].firstname}},<br/><br/>Thank you for recently reporting a suspicious email.The details of which are shown below. Our analysis indicates that this file was malicious. If you interacted with this email, either clicking a link or opening an atttachment, please alert Information Security by clicking the following link: <a href=\\\"{% prompt clicked %}\\\">{% prompt clicked %}</a>. If you did not click this link there is no further action required.<br/><br/><b>Malicous email details:</b><br /><b>Subject: </b> {{.check_inbox.subject}}<br /><b>Sent to report-phishing at: </b>{{.check_inbox.date}}<br /><br>Thank you,<br />Infromation Security", "recipients": "{{.check_inbox.from}}", "subject": "You received a malicious email"})
}

resource "tines_agent" "explode_attachments" {
    name = "Explode attachments"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.check_hybrid_analysis_for_hash.id]
    agent_options = jsonencode({"path": "{{.check_inbox.attachments}}", "mode": "explode", "to": "attachment"})
}

resource "tines_agent" "trigger_to_isolate_asset" {
    name = "Trigger to Isolate Asset"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.find_carbon_black_asset_by_hostname.id]
    agent_options = jsonencode({"rules": [{"path": "{{.update_jira_victim_found.prompt.status}}", "type": "regex", "value": "isolate_asset"}]})
}

resource "tines_agent" "hybrid_file_scan_still_in_progress" {
    name = "Hybrid file scan still in progress"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = [tines_agent.check_status_of_hybrid_file_scan.id]
    receiver_ids = [tines_agent.delay_event.id]
    agent_options = jsonencode({"rules": [{"path": "{{.check_status_of_hybrid_file_scan.body.state}}", "type": "regex", "value": "IN_PROGRESS"}]})
}

resource "tines_agent" "file_is_malicious" {
    name = "File is malicious"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.get_victim_details.id]
    agent_options = jsonencode({"rules": [{"path": "{{.search_virustotal_for_hash.body.positives}}{{.check_status_of_file_scan.body.positives}}", "type": "field>=value", "value": "1"}], "must_match": "1"})
}

resource "tines_agent" "user_confirmed_interaction_with_malicious_email" {
    name = "User confirmed interaction with malicious email"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.get_onelogin_cred.id]
    agent_options = jsonencode({"rules": [{"path": "{{.contact_victim.prompt.status}}", "type": "regex", "value": "clicked"}]})
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

resource "tines_agent" "hash_not_found_in_hybrid" {
    name = "Hash not found in Hybrid"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.submit_file_to_hybrid_analysis.id]
    agent_options = jsonencode({"rules": [{"path": "{{ .check_hybrid_analysis_for_hash.body | size }}", "type": "field==value", "value": "0"}]})
}

resource "tines_agent" "hash_found_in_hybrid" {
    name = "Hash found in Hybrid"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.file_is_malicious.id]
    agent_options = jsonencode({"rules": [{"path": "{{ .check_hybrid_analysis_for_hash.body | size }}", "type": "field>value", "value": "0"}]})
}

resource "tines_agent" "find_carbon_black_asset_by_hostname" {
    name = "Find Carbon Black Asset by Hostname"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.isolate_host_in_carbon_black.id]
    agent_options = jsonencode({"url": "https://cbr.tines.xyz/api/v1/sensor", "headers": {"X-Auth-Token": "{% credential cbapi %}"}, "log_error_on_status": [], "method": "get", "payload": {"hostname": "{{.get_dhcp_search_results.body.results.result.field[0].value.text}}"}})
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

resource "tines_agent" "extract_urls" {
    name = "Extract URLs"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.explode_urls.id]
    agent_options = jsonencode({"matchers": [{"path": "{{.check_inbox.body}}", "to": "urls", "regexp": "https?:\\/\\/[\\S]+"}], "mode": "extract"})
}

resource "tines_agent" "lock_victim_account" {
    name = "Lock victim account"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.update_service_now_victim_found.id]
    agent_options = jsonencode({"payload": {"status": "3"}, "url": "https://api.us.onelogin.com/api/1/users/{{.get_victim_details.body.data[0].id}}{{.find_additional_user_details.body.data[0].id}}", "log_error_on_status": [], "headers": {"authorization": "bearer:{{.get_onelogin_cred.body.data.first.access_token}}"}, "content_type": "json", "method": "put"})
}

resource "tines_agent" "check_hybrid_analysis_for_hash" {
    name = "Check hybrid analysis for hash"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.hash_not_found_in_hybrid.id, tines_agent.hash_found_in_hybrid.id]
    agent_options = jsonencode({"url": "https://www.hybrid-analysis.com/api/v2/search/hash", "headers": {"api-key": "{% credential HybridAnalysisAPI %}"}, "method": "post", "content_type": "form", "payload": {"hash": "{{.explode_attachments.attachment.md5}}", "user-agent": "Falcon Sandbox"}})
}

resource "tines_agent" "isolate_host_in_carbon_black" {
    name = "Isolate Host in Carbon Black"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.update_service_now_host_isolated.id]
    agent_options = jsonencode({"payload": {"group_id": 1, "network_isolation_enabled": "true"}, "url": "https://cbr.tines.xyz/api/v1/sensor/{{.find_carbon_black_asset_by_hostname.body.first.id}}", "log_error_on_status": [], "headers": {"X-Auth-Token": "{% credential cbapi %}"}, "content_type": "json", "method": "PUT"})
}

resource "tines_agent" "get_victim_details" {
    name = "Get victim details"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.contact_victim.id]
    agent_options = jsonencode({"url": "https://api.us.onelogin.com/api/1/users?email={{.check_inbox.from}}", "headers": {"authorization": "bearer:{% credential OneLogin %}"}, "method": "get", "log_error_on_status": []})
}

resource "tines_agent" "get_hybrid_scan_results" {
    name = "Get hybrid scan results"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.file_is_malicious.id]
    agent_options = jsonencode({"url": "https://www.hybrid-analysis.com/api/v2/report/{{.submit_file_to_hybrid_analysis.body.job_id}}/summary", "headers": {"api-key": "{% credential Hybrid %}"}, "log_error_on_status": [], "method": "get", "user_agent": "Falcon Sandbox"})
}

resource "tines_agent" "check_status_of_hybrid_file_scan" {
    name = "Check status of hybrid file scan"
    agent_type = "Agents::HTTPRequestAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.hybrid_scan_not_in_progress_or_complete.id, tines_agent.hybrid_file_scan_complete.id]
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

resource "tines_agent" "explode_urls" {
    name = "Explode URLs"
    agent_type = "Agents::EventTransformationAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.submit_to_vt.id]
    agent_options = jsonencode({"path": "{{.extract_urls.urls}}", "mode": "explode", "to": "url"})
}

resource "tines_agent" "url_is_malicious" {
    name = "URL is malicious"
    agent_type = "Agents::TriggerAgent"
    story_id = var.story_id
    keep_events_for = 0
    source_ids = []
    receiver_ids = [tines_agent.extract_domain.id]
    agent_options = jsonencode({"rules": [{"path": "{{ .submit_to_vt.body.positives }}", "type": "field>=value", "value": "1"}], "must_match": "1"})
}

