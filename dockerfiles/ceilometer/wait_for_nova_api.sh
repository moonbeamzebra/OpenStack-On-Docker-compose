#!/bin/bash


((count = $WAIT_LOOPS))
while [[ $count -ne 0 ]] ; do
    sleep $WAIT_SLEEP
    nova list
    rc=$?
    if [[ $rc -eq 0 ]] ; then
        echo "NOVA-API is responding OK"
        ((count = 1))
    else
        echo "NOVA-API is NOT responding yet"
    fi
    ((count = count - 1))
done

exit $rc

