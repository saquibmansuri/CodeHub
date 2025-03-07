#!/bin/bash

echo "=== Database and Table Comparison ===" > comparison_report.txt
echo "" >> comparison_report.txt

# Split into old and new sections
awk '/=== Old Server Stats ===/{p=1;next}/=== New Server Stats ===/{p=2;next}
    p==1{print > "old.tmp"}
    p==2{print > "new.tmp"}' detailed_stats.txt

# Get unique database names
awk -F'|' 'NF>1 {print $1}' old.tmp new.tmp | sort -u | sed 's/^ *//;s/ *$//' > databases.tmp

while read -r db; do
    echo -e "\nDatabase: $db" >> comparison_report.txt
    echo "----------------------------------------" >> comparison_report.txt
    printf "%-40s | %-10s | %-10s | %-10s\n" "Table" "Old Count" "New Count" "Match?" >> comparison_report.txt
    echo "--------------------------------------------------------------------------------" >> comparison_report.txt

    # Get tables and counts for this database
    grep "^$db[[:space:]]*|" old.tmp > old_db.tmp
    grep "^$db[[:space:]]*|" new.tmp > new_db.tmp

    # Get all unique tables for this database
    (awk -F'|' '{print $2}' old_db.tmp 2>/dev/null; 
     awk -F'|' '{print $2}' new_db.tmp 2>/dev/null) | sort -u | sed 's/^ *//;s/ *$//' > tables.tmp

    while read -r table; do
        old_count=$(grep "|[[:space:]]*$table[[:space:]]*|" old_db.tmp 2>/dev/null | awk -F'|' '{print $3}' | tr -d ' ')
        new_count=$(grep "|[[:space:]]*$table[[:space:]]*|" new_db.tmp 2>/dev/null | awk -F'|' '{print $3}' | tr -d ' ')

        [ -z "$old_count" ] && old_count="MISSING"
        [ -z "$new_count" ] && new_count="MISSING"

        if [ "$old_count" = "$new_count" ] && [ "$old_count" != "MISSING" ]; then
            match="✓"
        else
            match="❌"
        fi

        printf "%-40s | %-10s | %-10s | %-10s\n" "$table" "$old_count" "$new_count" "$match" >> comparison_report.txt
    done < tables.tmp
done < databases.tmp

# Clean up temporary files
rm -f old.tmp new.tmp old_db.tmp new_db.tmp tables.tmp databases.tmp

echo "Comparison complete. Check comparison_report.txt for results."
