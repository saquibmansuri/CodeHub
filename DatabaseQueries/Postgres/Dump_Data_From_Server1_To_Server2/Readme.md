# This shows how to take backup of existing Postgres Server 1 (containing multiple databases) && restoration process to a new Postgres Server 2 (used RDS for example)  


## POSTGES BACKUP/DUMP - TAKE BACKUP OF MULTIPLE DATABASES  
pg_dumpall -h [host] -p [port] -U [username] -v > full_backup.sql 2> backup_progress.log  
tail -f backup_progress.log #Check logs  
tail -n 20 full_backup.sql  #check last few lines of backup file to verify everything went well  


## THEN RESTORE IT TO THE NEW SERVER  
psql -h [new_server] -U [username] -v ON_ERROR_STOP=1 -f ./full_backup.sql > restore_output.log 2> restore_progress.log  
tail -f restore_output.log #for logs  
tail -f restore_progress.log #for progress  

## Step3 - Get stats
Run stats.sh  

## Step4 - Compare Stats
Run compare_stats.sh
