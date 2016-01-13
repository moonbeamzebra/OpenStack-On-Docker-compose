#!/bin/bash


((count = $WAIT_LOOPS))
while [[ $count -ne 0 ]] ; do
    sleep $WAIT_SLEEP
    n=`openstack endpoint list -f value -c Interface | grep admin1 | wc -l`  
    if [[ $n -eq 1 ]] ; then
        echo "Keystone admin endpoint created OK"
        ((count = 1))
    else
        echo "Keystone admin endpoint NOT yet"
    fi
    ((count = count - 1))
done

exit $rc

