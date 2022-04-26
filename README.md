# MailChimp GCP Import Task

## Steps of Process: 

### Step1: Ingestion of original data, update data and upserting the updates into original table:
1. Created a personal project on GCP and created copies of 'cycle_hires' and 'cycle_stations' tables from the london_bicyle dataset on GCS
2. Create additional tables with updates for 'cycle_hires' and 'cycle_stations' named 'cycle_hires_updates' and 'cycle_station_updates' respectively by using the json files containing updates as source
3. Upserted the rows for the two original tables using the update tables using MERGE INTO... clause (referenced the [medium](https://medium.com/@chekanskiy/bigquery-upsert-with-execute-immediate-8399e9997753) post to update multiple columns at once dynamically

### Step2: Created a reporting table with the aggregations mentioned in the task requirements (please ref SQL file in the repo)
