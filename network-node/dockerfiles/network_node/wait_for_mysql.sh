#!/bin/bash


((count = $WAIT_LOOPS))
while [[ $count -ne 0 ]] ; do
    sleep $WAIT_SLEEP
    mysql --user=root --password=$MYSQL_ROOT_PASSWORD -h $MYSQLHOST -P 3306
    rc=$?
    if [[ $rc -eq 0 ]] ; then
        echo "MYSQL is responding OK"
        ((count = 1))
    else
        echo "MYSQL is NOT responding yet"
    fi
    ((count = count - 1))
done

exit $rc

