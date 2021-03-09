# Duo Security

## Overview

Example Duo Security actions and workflows.

## Setup

Duo Security provides two primary API 'applications': the Auth API and the Admin API. Each of these applications contains a separate credential set. This story aims to abstract that away by identifying if a request needs to go to an '/admin/' API endpoint or an '/auth/' API endpoint. If you are only utilizing one of these API sets, you may only need to create one set of credentials.

+ Create a Resource named 'duo_api_hostname' and enter your Duo Security tenant name (admin-d59a1f14.duosecurity.com)
+ Create a Resource named 'duo_admin_integration_key' with the Duo application's integration key if you are using the Admin API
+ Create a Resource named 'duo_auth_integration_key' with the Duo application's integration key if you are using the Auth API
+ Create a Credential named 'duo_admin_secret_key' with the Duo application's secret key if you are using the Admin API
+ Create a Credential named 'duo_auth_secret_key' with the Duo application's secret key if you are using the Auth API
