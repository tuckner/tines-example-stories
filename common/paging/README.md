# Paging
An example of how to loop and page through an API and then consolidate the results (which may be unnecessary). This example is unique because Notion does not provide:

- The number of pages available
- The number of items remaining

Because of those obstacles, this workflow will built a counter of number of pages seen to calculate the number of events that should be imploded (consolidated). Once the paging has been completed, the 'Final Count' event will emit and set the number of events that should be consolidated. By default, the limit will be 100 events to be consolidated if the final count is more than 100.

![image](https://user-images.githubusercontent.com/8551704/121271747-f582d900-c889-11eb-9510-f42aca81e6ec.png)
