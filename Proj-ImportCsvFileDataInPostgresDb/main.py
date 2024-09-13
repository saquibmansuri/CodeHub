# THIS SCRIPT HAS OPTION FOR FRESH IMPORT, APPEND DATA TO EXISTING TABLE & REVERT PARTICULAR SESSION DATA FROM A TABLE

import pandas as pd
import numpy as np
import string
import random
from sqlalchemy import create_engine, text

# Database configuration
DB_CONFIG = {
    'dbname': 'saquib-testing',
    'user': 'climateintelligenceadmin5043',
    'password': 'jM28bn5hqesUdAZD',
    'host': 'climate-intelligence-postgres.postgres.database.azure.com',
    'port': '5432'
}

def generate_session_id():
    return ''.join(random.choices(string.ascii_letters + string.digits, k=10))

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

def create_table_with_inferred_schema(df, table_name, engine, session_id):
    print("Inferring data types and sanitizing column names...")
    df.columns = [sanitize_column_name(col) for col in df.columns]
    df['import_session_id'] = session_id  # Add the session_id column to dataframe

    # Print column names and inferred SQL types
    sql_types = {col: infer_sql_type(df[col].dtype, df[col]) for col in df.columns}
    for col, sql_type in sql_types.items():
        print(f"Column '{col}' inferred as SQL type '{sql_type}'")

    columns_with_types = ", ".join([f'"{col}" {sql_type}' for col, sql_type in sql_types.items()])
    create_table_sql = f'CREATE TABLE "{table_name}" ({columns_with_types});'
    
    print(f'Creating table "{table_name}" in the database...')
    with engine.connect() as conn:
        conn.execute(text(create_table_sql))
    print(f'Table "{table_name}" created successfully with session_id column.')

def check_and_add_session_column(table_name, engine, session_id):
    with engine.connect() as conn:
        check_column_sql = f"SELECT column_name FROM information_schema.columns WHERE table_name='{table_name}' and column_name='import_session_id';"
        result = conn.execute(text(check_column_sql)).fetchone()
        if not result:
            print("Adding 'import_session_id' column to existing table...")
            add_column_sql = f'ALTER TABLE "{table_name}" ADD COLUMN "import_session_id" VARCHAR;'
            conn.execute(text(add_column_sql))
            print("Column added successfully.")
        else:
            print("'import_session_id' column already exists in the table.")

def insert_data_with_rollback(df, table_name, engine, session_id, batch_size=50000):
    total_rows = len(df)
    print(f"Total rows to insert: {total_rows}")
    success = True  # Flag to track the success of data insertion

    with engine.connect() as conn:
        trans = conn.begin()  # Begin one transaction for the entire import session

        try:
            # Process each batch
            for start in range(0, total_rows, batch_size):
                end = min(start + batch_size, total_rows)
                batch_df = df.iloc[start:end].copy()
                batch_df['import_session_id'] = session_id  # Ensure session_id is in the DataFrame correctly

                print(f"Inserting rows {start + 1} to {end}...")
                batch_df.to_sql(table_name, conn, index=False, if_exists='append', method='multi')
                print(f"Rows {start + 1} to {end} inserted successfully.")

            trans.commit()  # Commit the entire transaction if all batches succeed
        except Exception as e:
            print(f"An error occurred during batch insertion: {e}")
            trans.rollback()  # Rollback the entire transaction if any batch fails
            success = False

    return success

def delete_all_records_by_session_id(table_name, session_id, engine):
    with engine.connect() as conn:
        trans = conn.begin()  # Begin a transaction explicitly

        try:
            table_name = f'"{table_name}"'
            
            # Single DELETE statement for all rows with matching session_id
            delete_sql = f"DELETE FROM {table_name} WHERE import_session_id = :session_id"
            rows_deleted = conn.execute(text(delete_sql), {'session_id': session_id}).rowcount
            print(f"Deleted {rows_deleted} rows.")
            
            # Commit the transaction after deletion
            trans.commit()
        except Exception as e:
            print(f"An error occurred during deletion: {e}")
            trans.rollback()  # Rollback the transaction in case of error

def main():
    print("Select an operation: \n1. Fresh Upload\n2. Append in Existing Table\n3. Revert Data")
    choice = input("Enter your choice (1, 2, or 3): ").strip()
    engine = connect_db()

    if choice in ['1', '2']:
        session_id = generate_session_id()
        print(f"Generated session ID for this operation: {session_id}")
        csv_file_path = input("Enter the path to your CSV file: ")
        print("Reading the CSV file for column names and datatypes...")
        df = pd.read_csv(csv_file_path)
        print(f"CSV file '{csv_file_path}' successfully loaded in memory with {len(df)} rows and {len(df.columns)} columns.")

    if choice == '1':
        table_name = input("Enter the name for the new table: ")
        create_table_with_inferred_schema(df, table_name, engine, session_id)
        success = insert_data_with_rollback(df, table_name, engine, session_id)

    elif choice == '2':
        table_name = input("Enter the name of the existing table to append data to: ")
        check_and_add_session_column(table_name, engine, session_id)
        success = insert_data_with_rollback(df, table_name, engine, session_id)

    elif choice == '3':
        table_name = input("Enter the table name for data deletion: ")
        session_id_to_delete = input("Enter the import_session_id to identify records to delete: ")
        delete_all_records_by_session_id(table_name, session_id_to_delete, engine)
        success = True

    else:
        print("Invalid choice. Please restart the script and choose a valid option.")
        success = False

    if success:
        print("Operation completed successfully without errors.")
    else:
        print("Operation failed with errors.")

if __name__ == '__main__':
    main()
