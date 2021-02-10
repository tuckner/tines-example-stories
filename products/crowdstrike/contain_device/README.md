# Crowdstrike - Contain Device
Receives a Crowdstrike Host ID, and attempts to contain that device on the network.

If configured with a Slack webhook, a notification will be sent to a Slack channel.

To configure a Slack webhook, create a 'Resource' called `slack_webhook_url` containing the webhook URL for a Slack tenant.