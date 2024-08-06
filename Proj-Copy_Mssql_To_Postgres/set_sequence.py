# This script sets primary key value to max+1 for all tables containing columns with integer datatype 

import psycopg2

def set_sequence_to_max_id(database, user, password, host, port):
    try:
        # Connect to PostgreSQL database
        connection = psycopg2.connect(
            database=database,
            user=user,
            password=password,
            host=host,
            port=port
        )
        cursor = connection.cursor()

        # Retrive all table name from the public schema
        cursor.execute("""SELECT table_name 
            FROM information_schema.tables
            WHERE table_schema = 'public'
            ORDER BY table_name;
            """)

        # Fetch all table names
        tables = cursor.fetchall()

        # Print table names
        print("Tables in the public schema:")
        for table in tables:
            print(table[0])
            cursor.execute(f"""
                SELECT column_name, data_type
                FROM information_schema.columns
                WHERE table_name = '{table[0]}'
                            and column_name='Id'
                ORDER BY ordinal_position;
            """)

            # Fetch all column data types
            columns = cursor.fetchall()
            
            # Print column data types
            print(f"Column data types for table {table[0]}:")
            for column in columns:
                print(f"{column[0]}: {column[1]}")
                column_name= column[0]
                column_data_type= column[1]
                print(f"{column_name}")
                print(f"{column_data_type}")
                # Check id column datatype is integer or not
                if column_data_type == 'integer':
                    # Retrieve the maximum Id from StatusDetail table
                    cursor.execute('SELECT MAX("Id") + 1 FROM "'+table[0]+'"')
                    print('SELECT MAX("Id") + 1 FROM "'+table[0]+'"')
                    max_id = cursor.fetchone()[0]        
                    print(max_id)
                    if max_id is None:
                        max_id = 1  # If table is empty, start sequence from 1
                    # Retrieve the sequence name associated with the Id column
                    print('SELECT pg_get_serial_sequence(\'"'+table[0]+'"\', \'Id\');') 
                    cursor.execute('SELECT pg_get_serial_sequence(\'"'+table[0]+'"\', \'Id\');')
                    sequence_name = cursor.fetchone()[0]
                    print(sequence_name)
                    if sequence_name:
                        # Construct and execute the ALTER SEQUENCE command
                        alter_sequence_sql = f'ALTER SEQUENCE {sequence_name} RESTART WITH {max_id};'
                        cursor.execute(alter_sequence_sql)
                        connection.commit()
                        print(f'Successfully set {sequence_name} to restart with {max_id}')
                    else:
                        print('Sequence not found for {table[0]}.Id')
                else:
                    print('Id is not integer')

    except (Exception, psycopg2.DatabaseError) as error:
        print(f'Error: {error}')
    finally:
        if connection:
            cursor.close()
            connection.close()

# Replace with your PostgreSQL database credentials
database = "test-db"
user = "myuser"
password = "mypassword"
host = "localhost"
port = "5432"

set_sequence_to_max_id(database, user, password, host, port)
