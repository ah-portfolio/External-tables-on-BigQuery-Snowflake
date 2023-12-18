# External tables on BigQuery vs Snowflake 
## Introduction :
In the ever-evolving landscape of data analytics and cloud computing, the utilization of external tables has emerged as a pivotal strategy to enhance data processing efficiency. This project aims to delve into the comparative performance analysis of employing external tables in two prominent data warehouse platforms: Google BigQuery and Snowflake.

External tables play a crucial role in augmenting the scalability and flexibility of data storage and retrieval processes. By allowing users to access and analyze data residing in external storage systems, such as cloud storage or data lakes. 

Whether managing vast datasets, conducting cross-platform analytics, or enabling real-time data access, external tables shine in various scenarios. They become particularly valuable in scenarios where data spans multiple cloud platforms or when leveraging existing data lakes for analysis without the need for expensive data transfer operations.

## Context :
### Fake data
In order to test datawarehouses performances, we need data ! It's time to generate our own data. Let's gone a take a basic use case with two tables in order to perform joins operation :
  - Orders
  - Customers

A Python code generates synthetic data for customer and order tables using the Faker library and Dask dataframes. It creates hundreds of Parquet files for both tables, with customer data containing information such as customer ID, name, email, and phone, while order data includes order ID, customer ID, product, and amount. The code saves the Dask dataframes to Parquet files, appending data in each iteration.

Our data set is constituted by 297 900 rows of customers, and 149 000 000 rows of orders (around 6,5 Go). It starts to be an interesting dataset to test performances.

This dataset will be uploaded to a Google Cloud Storage bucket in two differnet folder and let's gone test it !

### External tables creation

#### Big Query
`CREATE EXTERNAL TABLE mygcpaccount.test_perf.orders OPTIONS(format="PARQUET",uris=["gs://test_perf_bq_sf/orders/part.*.parquet"]);`

`CREATE EXTERNAL TABLE mygcpaccount.test_perf.customer OPTIONS(format="PARQUET",uris["gs://test_perf_bq_sf/customers/part.*.parquet"]);`

![image](https://github.com/ah-portfolio/External-tables-on-BigQuery-Snowflake/assets/110063004/75527feb-0c0b-41b7-a3fb-4c2b4d26acb7)

PS : in order to test with coherent results each time, we disabled this bigquery feature.

#### Snowflake
First step : create a storage integration : 
```
CREATE STORAGE INTEGRATION gcs_test_perf_bq_sf
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = GCS
ENABLED = TRUE
STORAGE_ALLOWED_LOCATIONS  = ('gcs://test_perf_bq_sf');
```
After that we run this command to get the GCP service account : `DESC STORAGE INTEGRATION gcs_test_perf_bq_sf`
Then we add to this service account authorization on the GCS bucket where data is stored.

Let's gone create a Snowflake schema and stage with this command :
```
CREATE SCHEMA TEST_DB.TEST_PERF;
USE SCHEMA TEST_DB.TEST_PERF;
CREATE OR REPLACE STAGE gcs_stage
STORAGE_INTEGRATION = gcs_test_perf_bq_sf
URL = 'gcs://test_perf_bq_sf'
FILE_FORMAT = (TYPE = 'PARQUET');
create or replace file format myparquet 
type = 'PARQUET';
```
Now we can access data, and create external tables from this stage.

PS : in order to test with coherent results each time, we disabled this snowflake feature : `alter session set USE_CACHED_RESULT = FALSE;`

PS : The GCS bucket, external tables in BigQuery and the snowflake account are all in the same region: europe-west2

## Performances comparison :

We are going to mesure performances on four operations without LIMIT operator:

  1. Select where : on the bigest table which is orders
  2. Count(*) : on the bigest table which is orders
  3. Inner Join : between orders and customers
  4. Agregation : find the number of orders per customer
      
### Naive behaviour 

Lets consider that we are explorating the dataset naively, without any optimization. 

| DW            | Sowflake XS   | Snwoflake M   | Snwoflake XL  |Big Query      |
|:-------------:|:-------------:|--------------:|--------------:|--------------:|
| SELECT WHERE  |       2min 02s|            26s|             1s|             1s|
| COUNT(*)      |       1min 01s|            14s|             4s|             1s|
| INNER JOIN    |       8min 22s|       2min 06s|            33s|            24s|
| AGREGATION    |       2min 12s|            38s|            12s|            55s|


Partitionning : 

-> BigQuery automate partitionning (by using schema auto detect) at the table creation. Each parquet is called part.*.parquet, the star correspond to the column null_dask_index.
-> Snowflake can automate partitionning by creating a gcp pub/sub, each file added on the gcs bucket will trigger an auto refresh (not used here).

## Conclusion :

### Performance Gap
Snowflake data warehouse exhibits a noticeable performance gap that varies with the size of the data. The performance may differ significantly depending on the scale of the operation

### BigQuery Performance
BigQuery demonstrates competitive performance, particularly with Snowflake XL. It holds its own in terms of processing capabilities, approaching the performance levels of Snowflake.

### Price Considerations
While both Snowflake and BigQuery offer robust performance, the cost aspect should not be overlooked. Snowflake can be more expensive than BigQuery, and understanding the pricing models is crucial for making informed decisions.

### Complexity 
Snowflake may introduce added complexity and costs when querying external tables. It's important to carefully evaluate the specific use case and requirements to determine the optimal solution between Snowflake and BigQuery.

In conclusion, the choice between Snowflake and BigQuery depends on a variety of factors, including performance needs, cost considerations, and the complexity of querying external tables. Organizations should conduct a thorough analysis based on their unique requirements to make the most informed decision for their data processing and analytics workflows.
