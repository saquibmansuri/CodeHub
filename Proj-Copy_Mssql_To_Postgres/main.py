# This script can copy data from Sql to Postgres database ensuring constraints are maintained on both databases.
# Note: Before running the script please ensure both databases contains same tables, schema and constraints.

import pyodbc
import psycopg2
from psycopg2 import extras
import networkx as nx


def get_columns_and_types(sql_conn, table_name):
    # This query fetches all column names and types
    query = f"""
    SELECT COLUMN_NAME, DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = '{table_name}';
    """
    cursor = sql_conn.cursor()
    cursor.execute(query)
    columns = cursor.fetchall()
    datetimeoffset_columns = [col[0] for col in columns if col[1] == 'datetimeoffset']
    all_columns = [col[0] for col in columns]
    return datetimeoffset_columns, all_columns



def construct_query(table_name, datetimeoffset_columns, all_columns):
    # Enclose identifiers in square brackets to handle reserved keywords
    safe_table_name = f"[{table_name}]"
    columns_list = [
        f"CAST([{col}] AS DATETIME) AS [{col}]" if col in datetimeoffset_columns else f"[{col}]"
        for col in all_columns
    ]
    columns_str = ', '.join(columns_list)
    query = f"SELECT {columns_str} FROM {safe_table_name}"
    return query
def connect_sqlserver():
    """Connect to the SQL Server database."""
    return pyodbc.connect('DRIVER={ODBC Driver 18 for SQL Server};SERVER=tcp:<ip/hostname>,1433;DATABASE=<db-name>;UID=<username>;PWD=<password>;Encrypt=yes;TrustServerCertificate=yes;Connection Timeout=30;')

def connect_postgres():
    """Connect to the PostgreSQL database."""
    return psycopg2.connect("postgresql://<username>:<password>@<server_ip>:5432/<db_name>?connect_timeout=30")

def detect_and_remove_cycles(G):
    try:
        cycle = nx.find_cycle(G, orientation='original')
        print("Cycle detected:", cycle)
        # Optional: Remove an edge from the cycle
        G.remove_edge(cycle[0][0], cycle[0][1])
        # Note: Removing edges can have implications on your data model.
    except nx.NetworkXNoCycle:
        print("No cycle found in the graph.")
    return G
def extract_foreign_keys(conn):
    """Extract foreign key relationships from the database."""
    query = """
    SELECT 
        fk.name AS FK_name,
        tp.name AS parent_table,
        ref.name AS referenced_table
    FROM 
        sys.foreign_keys AS fk
    INNER JOIN 
        sys.tables AS tp ON fk.parent_object_id = tp.object_id
    INNER JOIN 
        sys.tables AS ref ON fk.referenced_object_id = ref.object_id;
    """
    cursor = conn.cursor()
    cursor.execute(query)
    return cursor.fetchall()

def build_dependency_graph(fks):
    """Build a dependency graph from foreign key relationships."""
    G = nx.DiGraph()
    for fk in fks:
        # Add edge from parent (dependent) table to referenced (independent) table
        G.add_edge(fk.parent_table, fk.referenced_table)
    return G

def fetch_data(sql_conn, table):
    """Fetch data from SQL Server."""
    cursor = sql_conn.cursor()
    cursor.execute(f"SELECT * FROM {table}")
    columns = [column[0] for column in cursor.description]
    while True:
        rows = cursor.fetchmany(1000)
        if not rows:
            break
        yield from rows

def insert_data(postgres_conn, table, rows, columns):
    """Insert data into PostgreSQL using batch insertion."""
    cursor = postgres_conn.cursor()
    # Ensure table and column names are quoted to preserve case sensitivity
    quoted_table = f'"{table}"'
    quoted_columns = ', '.join([f'"{col}"' for col in columns])
    template = ','.join(['%s'] * len(columns))
    insert_query = f"INSERT INTO {quoted_table} ({quoted_columns}) VALUES ({template})"
    try:
        extras.execute_batch(cursor, insert_query, rows)
        postgres_conn.commit()
    except psycopg2.Error as e:
        postgres_conn.rollback()
        print(f"Error inserting into {table}: {e}")

def transfer_table(sql_conn, postgres_conn, table):
    """Transfer data from SQL Server to PostgreSQL for one table."""
    print(f"Transferring data for table: {table}")
    cursor = sql_conn.cursor()
    datetimeoffset_columns, all_columns = get_columns_and_types(sql_conn, table)
    query = construct_query(table, datetimeoffset_columns, all_columns)
    cursor.execute(query)
    columns = [column[0] for column in cursor.description]  # Correctly fetch column names here

    buffer = []
    while True:
        rows = cursor.fetchmany(10000)
        if not rows:
            break
        buffer.extend(rows)
        if len(buffer) >= 10000:  # Batch size of 1000
            insert_data(postgres_conn, table, buffer, columns)
            buffer.clear()
    if buffer:
        insert_data(postgres_conn, table, buffer, columns)
    cursor.close()

def main():
    sql_conn = connect_sqlserver()
    postgres_conn = connect_postgres()
    foreign_keys = extract_foreign_keys(sql_conn)
    dependency_graph = build_dependency_graph(foreign_keys)
    dependency_graph = detect_and_remove_cycles(dependency_graph)
    sorted_tables = list(nx.topological_sort(dependency_graph))
    sorted_tables.reverse()

    print("Order of table migrations:")
    for table in sorted_tables:
        print(table)
        transfer_table(sql_conn, postgres_conn, table)

    sql_conn.close()
    postgres_conn.close()

if __name__ == "__main__":
    main()
