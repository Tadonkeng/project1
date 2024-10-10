#!/usr/bin/env bash
################################################################################
##
## NAME
##	postgresql-check.sh - Confirm PostgreSQL DB and Env Vars
##
## SYNOPSIS
##	postgresql-check.sh
##
## DESCRIPTION
##	The postgresql-check.sh script is intended to run as a job in the
##	Platform One mission apps cluster.  The job should run in an
##	application namespace.  Its purpose is to confirm the application's
##	database, users, and environment variables are correctly configured.
##	The job prints its test results to STDOUT making them available to
##	the application team through ArgoCD.
##
################################################################################


### Security stuff
set -uf -o pipefail
PATH="/bin:/usr/bin"


### Globals
HOME_DIR="/tmp"
PGPASS="${HOME_DIR}/.pgpass"
TEST_DIR="/tmp/scripts"
BIN_DIR="/tmp/scripts"


function main() {
    # Show them what env vars we use
    echo "Available environment vars:"
    echo "  \$PGHOST...............: The database hostname"
    echo "  \$PGPORT...............: The database listen port"
    echo "  \$PG_DATABASE..........: This application's database name"
    echo "  \$PG_USER..............: Admin user account"
    echo "  \$PG_RW_USER...........: Read-Write user account"
    echo "  \$PG_RO_USER...........: Read-Only user account"
    echo "  \$APP_DB_ADMIN_PASSWORD: Admin user password"
    echo "  \$APP_DB_RW_PASSWORD...: Read-Write user password"
    echo "  \$APP_DB_RW_PASSWORD...: Read-Only user password"
    echo

    # Create the .pgpass file from the env vars
    touch ${PGPASS}
    chmod 0600 ${PGPASS}
    echo -n "${PGHOST}:${PGPORT}:${PG_DATABASE}:${PG_USER}:" > ${PGPASS}
    echo    "${APP_DB_ADMIN_PASSWORD}" >> ${PGPASS} 
    echo -n "${PGHOST}:${PGPORT}:${PG_DATABASE}:${PG_RW_USER}:" >> ${PGPASS}
    echo    "${APP_DB_RW_PASSWORD}" >> ${PGPASS} 
    echo -n "${PGHOST}:${PGPORT}:${PG_DATABASE}:${PG_RO_USER}:" >> ${PGPASS}
    echo    "${APP_DB_RO_PASSWORD}" >> ${PGPASS}

    # For some reason, the RW and RO user permissions are not set properly.  Set them now
    set_user_perms

    # Create the test table
    echo "Running tests as the DB admin user"
    echo '====================================================================================='
    run_sql_file $PG_USER ${TEST_DIR}/create-table.sql
    run_sql_file $PG_USER ${TEST_DIR}/insert.sql
    echo

    echo "Running tests as the read-write user"
    echo '====================================================================================='
    run_sql_file $PG_RW_USER ${TEST_DIR}/create-table.sql
    run_sql_file $PG_RW_USER ${TEST_DIR}/select.sql
    run_sql_file $PG_RW_USER ${TEST_DIR}/insert.sql
    run_sql_file $PG_RW_USER ${TEST_DIR}/update.sql
    run_sql_file $PG_RW_USER ${TEST_DIR}/delete.sql
    echo

    echo "Running tests as the read-only user"
    echo '====================================================================================='
    run_sql_file $PG_RO_USER ${TEST_DIR}/create-table.sql
    run_sql_file $PG_RO_USER ${TEST_DIR}/select.sql
    run_sql_file $PG_RO_USER ${TEST_DIR}/insert.sql
    run_sql_file $PG_RO_USER ${TEST_DIR}/update.sql
    run_sql_file $PG_RO_USER ${TEST_DIR}/delete.sql
    echo
   
    # Remove the test table
    echo "Dropping the test table"
    echo '====================================================================================='
    run_sql_file $PG_USER ${TEST_DIR}/drop-table.sql
    echo
}


function run_sql_file() {
    echo "---> Executing the following query as user $1:"
    query=$(cat $2)
    echo "$query"
    export PGPASSFILE=${PGPASS}

    # Run the query, check the status    
    psql -h $PGHOST -U $1 -c "$query" $PG_DATABASE
    if [ $? -eq 0 ]; then
        echo "Success!"
    else
        echo "Query failed with status: $?"
    fi
    echo '-------------------------------------------------------------------------------------'
}


function run_sql_cmd() {
    echo "---> Executing the following query as user $1:"
    query=$2
    echo "$query"
    export PGPASSFILE=${PGPASS}

    # Run the query, check the status
    psql -h $PGHOST -U $1 -c "$query" $PG_DATABASE
    if [ $? -eq 0 ]; then
        echo "Success!"
    else
        echo "Query failed with status: $?"
    fi
    echo '-------------------------------------------------------------------------------------'
}


function set_user_perms() {
    # Replace the placeholder in the permissions sql files
    app_name=${PG_DATABASE::-3}

    # Because the container has a read-only file system, we'll run sed to set the
    # SQL command, save it as an env var and use psql's -c flag
    export ro_grant_sql=$(sed "s/<APP>/${app_name}/g" ${TEST_DIR}/grant-ro.sql)
    export rw_grant_sql=$(sed "s/<APP>/${app_name}/g" ${TEST_DIR}/grant-rw.sql)
    export rw_usage_grant_sql=$(sed "s/<APP>/${app_name}/g" ${TEST_DIR}/grant-usage-rw.sql)

    run_sql_cmd $PG_USER "$ro_grant_sql"
    run_sql_cmd $PG_USER "$rw_grant_sql"
    run_sql_cmd $PG_USER "$rw_usage_grant_sql"
}


main $@
