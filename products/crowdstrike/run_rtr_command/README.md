---
title: CrowdStrike - Run RTR Command
author: John Tuckner
date: 2020-01-02
hero: ../images/logo.png 
excerpt: Run an RTR command in CrowdStrike using Tines
category: "products"
tags:
  - "crowdstrike"
  - "edr"
  - "response"
---

# Crowdstrike - Run RTR Command

This story will run a given Crowdstrike RtR command against a provided Host ID.

All default RtR scripts can be used, e.g.:
- ls
- memdump
- shutdown

Additionally, custom RtR scripts uploaded into the Crowdstrike tenant can be executed as:

`runscript -CloudFile="scriptName" -CommandLine=""`
