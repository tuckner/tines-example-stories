---
title: CrowdStrike - Contain Device
author: John Tuckner
date: 2020-01-02
hero: ../images/logo.png 
excerpt: Contain a device using CrowdStrike
category: "products"
tags:
  - "crowdstrike"
  - "edr"
  - "response"
---

# Crowdstrike - Contain Device

Receives a Crowdstrike Host ID, and attempts to contain that device on the network.

If configured with a Slack webhook, a notification will be sent to a Slack channel.

To configure a Slack webhook, create a 'Resource' called `slack_webhook_url` containing the webhook URL for a Slack tenant.