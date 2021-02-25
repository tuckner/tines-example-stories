---
title: Mimecast STS
author: John Tuckner
date: 2020-01-03
hero: ../../images/logo.png
excerpt: A Tines example story
---

# Mimecast STS
## Overview

A Send to Story workflow to enable querying various Mimecast endpoints with the correct HTTP request structure.

## Setup
Import the Send to Story 'Mimecast STS'
Ensure that the story is enabled for 'Send to Story'

Create a Text Credential 'mimecast-app-id'
Create a Text Credential 'mimecast-app-key'
Create a Text Credential 'mimecast-access-key'
Create a Text Credential 'mimecast-secret-key'

Search for a Mimecast template in the templates panel e.g. 'Get Account Details'
Drag this template onto the storyboard
Ensure that the name of the Story selected in the Send to Story Agent is the name of your Story 
Click 'Run'

Now you should be able to pass any data to Mimecast dynamically



Deploy this story by clicking [here](https://quiet-vista-5142.tines.io/forms/e9c00ffdaa5924f1bc4810b6d030cb34).