CREATE or replace STORAGE INTEGRATION gcs_test_perf_bq_sf
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = GCS
ENABLED = TRUE
STORAGE_ALLOWED_LOCATIONS  = ('gcs://mybucket/');

CREATE OR REPLACE STAGE gcs_stage
STORAGE_INTEGRATION = gcs_test_perf_bq_sf
URL = 'gcs://mybucket'
FILE_FORMAT = (TYPE = 'PARQUET');



create or replace file format myparquet 
type = 'PARQUET';

--CUSTOMERS TABLE :
    --READING
    SELECT $1:customer_name::varchar, $1:customer_id::varchar ,$1:email::varchar(100),$1:phone::varchar(100),$1:__null_dask_index__::integer FROM @gcs_stage/customers (file_format =>myparquet);
    --CREATING AS EXTERNAL TABLE 
    create or replace external TABLE customers
    (
    customer_id varchar as ($1:customer_id::varchar(100)),
    customer_name varchar as($1:customer_name::varchar(100)),
    email varchar as($1:email::varchar(100)),
    phone varchar as($1:phone::varchar(100)),
    index0 integer as ($1:__null_dask_index__::integer)
    )
    WITH location = @gcs_stage/customers/ 
    file_format = (TYPE = PARQUET)
    AUTO_REFRESH = FALSE;

--ORDERS TABLE :
    --READING
    SELECT $1:order_id, $1:customer_id ,$1:product,$1:amount,$1:__null_dask_index__ FROM @gcs_stage/orders (file_format =>myparquet) ;
    --CREATING AS EXTERNAL TABLE 
    create or replace external TABLE orders
    (
    order_id varchar as ($1:order_id::varchar(100)),
    customer_id varchar as($1:customer_id::varchar(100)),
    product varchar as($1:product::varchar(100)),
    amount varchar as($1:amount::varchar(100)),
    index0 integer as ($1:__null_dask_index__::integer)
    )
    WITH location = @gcs_stage/orders/ 
    file_format = (TYPE = PARQUET)
    AUTO_REFRESH = FALSE;

--the first column value is composed by the line in json format
--SELECT WHERE
select * exclude(value) from TEST_DB.TEST_PERF.orders  where customer_id = '63a96e34-43de-443c-a0a5-96b8aefbd6d4';

--COUNT(*)
select count(*) from TEST_DB.TEST_PERF.orders;

--INNER JOIN
select * from TEST_DB.TEST_PERF.orders orders JOIN  TEST_DB.TEST_PERF.customers cust ON orders.customer_id = cust.customer_id;

--AGREGATION
with orders
as 
(
select * from TEST_DB.TEST_PERF.orders
),
customers
as
(
select * from TEST_DB.TEST_PERF.customers
)
select 
customers.customer_name,
count(*) as number_of_orders
FROM orders JOIN customers
ON orders.customer_id = customers.customer_id
group by 1;
