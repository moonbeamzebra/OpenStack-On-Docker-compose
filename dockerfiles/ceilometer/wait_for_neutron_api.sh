#!/bin/bash


((count = $WAIT_LOOPS))
while [[ $count -ne 0 ]] ; do
    sleep $WAIT_SLEEP
    neutron net-list
    rc=$?
    if [[ $rc -eq 0 ]] ; then
        echo "NEUTRON-API is responding OK"
        ((count = 1))
    else
        echo "NEUTRON-API is NOT responding yet"
    fi
    ((count = count - 1))
done

exit $rc

