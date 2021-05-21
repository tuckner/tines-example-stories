# Throttle
This workflow allows for throttling of requests using AWS SQS and Tines scheduled actions. Here, a user can submit a form with some text. An SQS message will get entered and then stop at the Implode action. In the branch on the right, 'Receive SQS Message' will be scheduled to retrieve items from the queue once per minute. If it successfully retrieves a new message, it will pass the 'Check if Message' trigger and pass the event along to the implode action to join up the two branches.

![image](https://user-images.githubusercontent.com/8551704/119170874-7a1bcd80-ba29-11eb-83c0-a6d2e127206e.png)
