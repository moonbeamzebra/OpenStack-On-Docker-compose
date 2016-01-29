#!/bin/bash


((count = $WAIT_LOOPS))
while [[ $count -ne 0 ]] ; do
    sleep $WAIT_SLEEP
    nc -zv rabbit-host 5672
    rc=$?
    if [[ $rc -eq 0 ]] ; then
        echo "RabbitMQ is responding OK"
        ((count = 1))
    else
        echo "RabbitMQ is NOT responding yet"
    fi
    ((count = count - 1))
done

exit $rc

