#!/bin/bash


((count = $WAIT_LOOPS))
while [[ $count -ne 0 ]] ; do
    sleep $WAIT_SLEEP
    if [[ $1 == "noauth" ]] ; then
       mongo --host $MONGO_HOST --eval ' db '
    else
       mongo -u ceilometer -p $CEIL_DBPASS $MONGO_HOST/ceilometer --eval ' db '
    fi
    rc=$?
    if [[ $rc -eq 0 ]] ; then
        echo "MONGO is responding OK"
        ((count = 1))
    else
        echo "MONGO is NOT responding yet"
    fi
    ((count = count - 1))
done

exit $rc

