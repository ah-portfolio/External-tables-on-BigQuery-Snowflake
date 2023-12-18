CREATE EXTERNAL TABLE mygcpaccount.test_perf.orders OPTIONS(format="PARQUET",uris=["gs://test_perf_bq_sf/orders/part.*.parquet"]);

CREATE EXTERNAL TABLE mygcpaccount.test_perf.customer OPTIONS(format="PARQUET",uris["gs://test_perf_bq_sf/customers/part.*.parquet"]);

--SELECT WHERE
SELECT * FROM `daring-card-399612.test_perf.orders` where customer_id = '63a96e34-43de-443c-a0a5-96b8aefbd6d4'

--COUNT(*)
SELECT count(*) FROM `daring-card-399612.test_perf.orders` ;

--INNER JOIN
SELECT * FROM `daring-card-399612.test_perf.orders` orders JOIN  `daring-card-399612.test_perf.customer` cust ON orders.customer_id = cust.customer_id;

--AGREGATION
with orders
as 
(
select * from `daring-card-399612.test_perf.orders`
),
customers
as
(
select * from `daring-card-399612.test_perf.customer`
)
select 
customers.customer_name,
count(*) as number_of_orders
FROM orders JOIN customers
ON orders.customer_id = customers.customer_id
group by 1;
