# Send to Story Breaks
There are some times when a complex child story needs to be broken out of a single flow, but ultimately should return to the parent story. This is an incredibly advanced 'feature', but does hold some use.

The key funtionality elements of Send to Story (Webhooks, 'agent_id', 'event_id', and Event Transforms) can be leveraged in unique ways to get this result.

In this flow, we will trigger a Send to Story which will send an event to a webhook 'Entry'. That webhook will receive a 'agent_id' and 'event_id' of the Send to Story action which the sub-flow should return to. We can utilize these pieces of information by including them in the 'Send to Continuance Webhook' HTTP Request Action that begins a new event flow in the third column.

The 'Continuance' flow receives the 'agent_id' and 'event_id' of the inital Send to Story call. In order for an action to return an event to a Send to Story action, two things must be true:

1. The first event (very important) of the flow must have 'agent_id' and 'event_id' keys. The action generating the first event of the chain does not need to be a Webhook but could be an Event Transform Action with the same name of the webhook immediately after which will overwrite the first event.
2. An Event Transform Action in message only mode and selected as an exit action in the Send to Story configuration.

With this example, you can see how complex paths can arrive back to a single Send to Story action even with breaks in the event chains.

![image](https://user-images.githubusercontent.com/8551704/118886344-6c960480-b8be-11eb-8983-860bdd8344ff.png)
