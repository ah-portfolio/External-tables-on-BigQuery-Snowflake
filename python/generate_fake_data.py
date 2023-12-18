import os
import shutil
import dask.dataframe as dd
from faker import Faker

# Set the seed for reproducibility
Faker.seed(0)

# Create a Faker instance
fake = Faker()

# Function to generate fake data for customers
def generate_customer_data(num_records, partitions=10):
    data = {
        'customer_id': [fake.uuid4() for _ in range(num_records)],
        'customer_name': [fake.name() for _ in range(num_records)],
        'email': [fake.email() for _ in range(num_records)],
        'phone': [fake.phone_number() for _ in range(num_records)],
    }
    return dd.from_dict(data, npartitions=partitions)

# Function to generate fake data for orders
def generate_order_data(num_records, customer_ids, partitions=10):
    data = {
        'order_id': [fake.uuid4() for _ in range(num_records)],
        'customer_id': [fake.random_element(elements=customer_ids) for _ in range(num_records)],
        'product': [fake.word() for _ in range(num_records)],
        'amount': [fake.random_int(min=1, max=1000) for _ in range(num_records)],
    }
    return dd.from_dict(data, npartitions=partitions)



# Set the number of records
num_customer_records = 1000  # You can adjust this based on your requirements
num_order_records = 500000    # You can adjust this based on your requirements
n = 1000

for i in range(n) :
    # Generate customer data
    ddf_customers = generate_customer_data(num_customer_records)

    # Generate order data
    customer_ids = ddf_customers['customer_id'].compute().tolist()
    ddf_orders = generate_order_data(num_order_records, customer_ids)

    # Reset the index to avoid overlapping divisions
    ddf_customers = ddf_customers.reset_index(drop=True)
    ddf_orders = ddf_orders.reset_index(drop=True)

    # Save dask DataFrames to parquet files
    customers_output_path = f'customers.parquet'
    orders_output_path = f'orders.parquet'

    ddf_customers.to_parquet(customers_output_path, engine='pyarrow',append = True)
    ddf_orders.to_parquet(orders_output_path, engine='pyarrow',append = True)

    # Display paths to the saved parquet files
    print(f'Customers data saved to: {customers_output_path}')
    print(f'Orders data saved to: {orders_output_path}')
