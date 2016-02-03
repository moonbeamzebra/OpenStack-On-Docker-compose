#!/bin/bash


((count = $WAIT_LOOPS))
while [[ $count -ne 0 ]] ; do
    sleep $WAIT_SLEEP
    glance image-list
    rc=$?
    if [[ $rc -eq 0 ]] ; then
        echo "GLANCE-API is responding OK"
        ((count = 1))
    else
        echo "GLANCE-API is NOT responding yet"
    fi
    ((count = count - 1))
done

exit $rc

