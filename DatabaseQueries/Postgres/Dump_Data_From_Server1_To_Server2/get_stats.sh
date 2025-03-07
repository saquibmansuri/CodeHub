#!/bin/bash

get_db_stats() {
    local host=$1
    local port=$2
    local user=$3
    local db=$4
    local output_file=$5
    local ssl_option=$6

    echo "Analyzing database: $db" >&2

    if [ "$ssl_option" = "ssl" ]; then
        export PGSSLMODE=verify-full
        export PGSSLROOTCERT=./rds-ca-cert.pem
    fi

    # Print header for this database
    printf "%-40s | %-40s | %-10s\n" "Database" "Table" "Row Count" >> "$output_file"
    printf "%-40s-+-%-40s-+-%-10s\n" "$(printf '%-.40s' "$(printf '%40s' '' | tr ' ' '-')")" "$(printf '%-.40s' "$(printf '%40s' '' | tr ' ' '-')")" "$(printf '%-.10s' "$(printf '%10s' '' | tr ' ' '-')")" >> "$output_file"

    # Get list of tables
    tables=$(psql -h $host -p $port -U $user -d "$db" -t -A -c "
        SELECT schemaname || '.' || tablename 
        FROM pg_tables 
        WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
        ORDER BY schemaname, tablename;")

    # For each table, get its row count
    for table in $tables; do
        count=$(psql -h $host -p $port -U $user -d "$db" -t -A -c "SELECT COUNT(*) FROM $table;")
        printf "%-40s | %-40s | %10s\n" "$db" "$table" "$count" >> "$output_file"
    done

    # Add a blank line after each database
    echo "" >> "$output_file"

    if [ "$ssl_option" = "ssl" ]; then
        unset PGSSLMODE
        unset PGSSLROOTCERT
    fi
}

# Clear the output file and add main header
> detailed_stats.txt
echo "=== Old Server Stats ===" > detailed_stats.txt
echo "" >> detailed_stats.txt

# For old server
export PGPASSWORD='oldserverpassword'
for db in $(psql -h [host_name] -p [port] -U [username] -t -c "SELECT datname FROM pg_database WHERE datname NOT IN ('template0', 'template1', 'postgres') AND datistemplate = false;"); do
    db=$(echo $db | tr -d ' ')
    if [ ! -z "$db" ]; then
        get_db_stats "[hostname]" "[port]" "[username]" "$db" detailed_stats.txt "nossl"
    fi
done

echo "=== New Server Stats ===" >> detailed_stats.txt
echo "" >> detailed_stats.txt

# For new server
export PGPASSWORD='newserverpassword'
export PGSSLMODE=verify-full
export PGSSLROOTCERT=./rds-ca-cert.pem #example new server ca certificate file

for db in $(psql -h [hostname] -p 5432 -U [username] -t -c "SELECT datname FROM pg_database WHERE datname NOT IN ('template0', 'template1', 'postgres', 'rdsadmin') AND datistemplate = false;"); do
    db=$(echo $db | tr -d ' ')
    if [ ! -z "$db" ]; then
        get_db_stats "[hostname]" "5432" "[username]" "$db" detailed_stats.txt "ssl"
    fi
done

unset PGSSLMODE
unset PGSSLROOTCERT

echo "Analysis complete. Check detailed_stats.txt for results."
