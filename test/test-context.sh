#!/bin/bash
# Test docker/context.pl

set -eo pipefail

SCRIPT="$(dirname $0)/../docker/context.pl"

function unset_vars {
    unset MYDB_HOST
    unset MYDB_NAME
    unset MYDB_PORT
    unset MYDB_RESOURCE
    unset MYDB_URL
    unset MYDB_USER
}

export CONTEXT="app"
export SECRETS_DIR="$(dirname $0)"

echo "Test: Constructed JDBC URL - default driver"
export MYDB_HOST="database.example.com"
export MYDB_NAME="MYDB"
export MYDB_PORT="1521"
export MYDB_RESOURCE="MYDB"
export MYDB_USER="DB-Admin"

diff <($SCRIPT) <(cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Context path="/app">
    <Resource name="jdbc/MYDB"
        auth="Container"
        type="javax.sql.DataSource"
        maxActive="10"
        maxIdle="2"
        maxWait="2000"
        username="DB-Admin"
        password="pass"
        driverClassName="oracle.jdbc.OracleDriver"
        url="jdbc:oracle:thin:@database.example.com:1521:MYDB"
        validationQuery="select 1 from dual"
    />
</Context>
EOF
)

if [ $? -eq 0 ]; then
    echo "test OK"
else
    echo "test failed"
fi
unset_vars

echo "Test: Constructed JDBC URL"
export MYDB_DRIVER="mssql"
export MYDB_HOST="database.example.com"
export MYDB_NAME="MYDB"
export MYDB_PORT="1521"
export MYDB_RESOURCE="MYDB"
export MYDB_USER="DB-Admin"

diff <($SCRIPT) <(cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Context path="/app">
    <Resource name="jdbc/MYDB"
        auth="Container"
        type="javax.sql.DataSource"
        maxActive="10"
        maxIdle="2"
        maxWait="2000"
        username="DB-Admin"
        password="pass"
        driverClassName="com.microsoft.jdbc.sqlserver.SQLServerDriver"
        url="jdbc:microsoft:sqlserver://database.example.com:1521;databaseName=MYDB"
        validationQuery="select 1"
    />
</Context>
EOF
)

if [ $? -eq 0 ]; then
    echo "test OK"
else
    echo "test failed"
fi
unset_vars

echo "Test: Specific JDBC URL"
export MYDB_DRIVER="mssql"
export MYDB_RESOURCE="MYDB"
export MYDB_URL="jdbc:oracle:thin:@(DESCRIPTION=(FAILOVER=ON)(ADDRESS=(PROTOCOL=TCP)(HOST=db01.example.com)(PORT=1521))(ADDRESS=(PROTOCOL=TCP)(HOST=db02.example.com)(PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=INSTANCE.example.com)))"
export MYDB_USER="DB-Admin"

diff <($SCRIPT) <(cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Context path="/app">
    <Resource name="jdbc/MYDB"
        auth="Container"
        type="javax.sql.DataSource"
        maxActive="10"
        maxIdle="2"
        maxWait="2000"
        username="DB-Admin"
        password="pass"
        driverClassName="oracle.jdbc.OracleDriver"
        url="jdbc:oracle:thin:@(DESCRIPTION=(FAILOVER=ON)(ADDRESS=(PROTOCOL=TCP)(HOST=db01.example.com)(PORT=1521))(ADDRESS=(PROTOCOL=TCP)(HOST=db02.example.com)(PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=INSTANCE.example.com)))"
        validationQuery="select 1 from dual"
    />
</Context>
EOF
)

if [ $? -eq 0 ]; then
    echo "test OK"
else
    echo "test failed"
fi
unset_vars

