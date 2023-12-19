#!/bin/bash
# directory to put the backup files
BACKUP_DIR=/home/<cron bash user>/backup
# Don't backup MySQL databases
IGNORE_DB="(^mysql|_schema$|sys)"
# include mysql and mysqldump binaries for cron bash user
PATH=$PATH:/usr/local/mysql/
# Number of days to keep backups
KEEP_BACKUPS_FOR=5 #days
# METHODS
TIMESTAMP=$(date +%F) # YYYY-MM-DD
function delete_old_backups(){
  echo "Deleting $BACKUP_DIR/*.sql.gz older than $KEEP_BACKUPS_FOR days"
  find $BACKUP_DIR -type f -name "*.sql.gz" -mtime +$KEEP_BACKUPS_FOR -exec rm {} \;
}
function database_list(){
  local show_databases_sql="SHOW DATABASES WHERE \`Database\` NOT REGEXP '$IGNORE_DB'"
  echo $(mysql --login-path=local -u backup -e "$show_databases_sql"|awk -F " " '{if (NR!=1) print $1}')
}
function echo_status(){
  printf '\n';
  printf ' %0.s' {0..100}
  printf '\r';
  printf "$1"'\n'
}
function backup_database(){
    backup_file="$BACKUP_DIR/$TIMESTAMP.$database.sql.gz"
    output+="$database => $backup_file\n"
    echo_status "...backing up $count of $total databases: $database"
    $(mysqldump --login-path=local --no-tablespaces -u backup $database | gzip -9 >
$backup_file)
}
function backup_databases(){
  local databases=$(database_list)
  local total=$(echo $databases | wc -w | xargs)
  local output=""
  local count=1
  for database in $databases; do
    backup_database
    local count=$((count+1))
  done
  echo -ne $output | column -t
}
# RUN SCRIPT
printf "Backing up databases\n"
delete_old_backups
backup_databases
printf "Finished\n\n"   
