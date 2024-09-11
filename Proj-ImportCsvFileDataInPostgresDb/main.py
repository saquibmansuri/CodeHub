import pandas as pd
from sqlalchemy import create_engine, MetaData, Table
from sqlalchemy.sql import text
import numpy as np

# Database configuration
DB_CONFIG = {
    'dbname': 'mydb',
    'user': 'myuser',
    'password': 'mypassword',
    'host': 'myhost',
    'port': '5432'
}

def connect_db():
    print("Connecting to the database...")
    conn_str = f"postgresql://{DB_CONFIG['user']}:{DB_CONFIG['password']}@{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['dbname']}"
    engine = create_engine(conn_str)
    print("Database Connection Successful")
    return engine

def infer_sql_type(pandas_type, column_data):
    if column_data.isnull().all():
        return 'VARCHAR'
    if pd.api.types.is_integer_dtype(pandas_type):
        # Check if any value exceeds the INTEGER limit
        if column_data.max() > np.iinfo(np.int32).max:
            return 'BIGINT'
        return 'INTEGER'
    elif pd.api.types.is_float_dtype(pandas_type):
        return 'FLOAT'
    elif pd.api.types.is_datetime64_any_dtype(pandas_type):
        return 'DATE'
    elif pd.api.types.is_string_dtype(pandas_type):
        return 'VARCHAR'
    else:
        return 'TEXT'

def sanitize_column_name(column_name):
    return column_name.replace("/", "_").replace(" ", "_").replace("-", "_").replace(".", "_")

def create_table_with_inferred_schema(df, table_name, conn):
    print("Inferring data types and sanitizing column names...")
    df.columns = [sanitize_column_name(col) for col in df.columns]

    sql_types = {col: infer_sql_type(df[col].dtype, df[col]) for col in df.columns}
    
    for col, sql_type in sql_types.items():
        print(f"Column '{col}' inferred as SQL type '{sql_type}'")

    columns_with_types = ", ".join([f'"{col}" {sql_type}' for col, sql_type in sql_types.items()])  # Double-quote columns too
    create_table_sql = f'CREATE TABLE "{table_name}" ({columns_with_types});'  # Use double quotes for the table name
    
    print(f'Creating table "{table_name}" in the database...')
    with conn.begin():
        conn.execute(text(create_table_sql))
    print(f'Table "{table_name}" created successfully.')

def preprocess_dataframe(df):
    # Example: convert specific columns to appropriate types if known
    # df['some_column'] = df['some_column'].astype('int64')  # Adjust as needed
    return df

def insert_data_in_batches(df, table_name, conn, batch_size=50000):
    total_rows = len(df)
    print(f"Total rows to insert: {total_rows}")
    success = True  # Flag to track the success of data insertion
    
    for start in range(0, total_rows, batch_size):
        end = min(start + batch_size, total_rows)
        batch_df = df[start:end]
        print(f"Inserting rows {start + 1} to {end}...")
        try:
            batch_df.to_sql(table_name, conn, index=False, if_exists='append')
            print(f"Rows {start + 1} to {end} inserted successfully.")
        except Exception as e:
            print(f"An error occurred during batch insertion: {e}")
            success = False  # Set success to False if an error occurs
    
    return success  # Return the success status

def main():
    csv_file_path = input("Enter the path to your CSV file: ")
    print("Reading the CSV file for column names and datatypes...")
    
    df = pd.read_csv(csv_file_path)
    df = preprocess_dataframe(df)  # Preprocess the DataFrame if necessary
    print(f"CSV file '{csv_file_path}' successfully loaded in memory with {len(df)} rows and {len(df.columns)} columns.")
    
    engine = connect_db()
    conn = engine.connect()

    create_new_table = input("Do you want to create a new table? (yes/no): ").strip().lower()

    if create_new_table == 'yes':
        table_name = input("Enter the name for the new table: ")
        create_table_with_inferred_schema(df, table_name, conn)
        print("Starting to copy data in batches of 50,000 rows...")
        success = insert_data_in_batches(df, table_name, conn)
    elif create_new_table == 'no':
        table_name = input("Enter the name of the existing table to append data to: ")
        try:
            print(f"Appending data to existing table '{table_name}' in batches of 50,000 rows...")
            success = insert_data_in_batches(df, table_name, conn)
        except Exception as e:
            print(f"An error occurred: {e}")
            success = False  # Set success to False if an error occurs
    else:
        print("Invalid option selected. Please choose 'yes' or 'no'.")
        success = False  # Set success to False for invalid options
    
    conn.close()
    if success:
        print("DATA IMPORT SUCCESSFUL WITHOUT ERRORS")
    else:
        print("DATA IMPORT FAILED WITH ERRORS")
    print("Database connection closed.")

if __name__ == '__main__':
    main()
