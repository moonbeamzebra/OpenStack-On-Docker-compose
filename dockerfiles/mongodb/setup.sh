#! /bin/bash

sleep 5

service mongodb stop
sleep 5
rm -f /var/lib/mongodb/journal/prealloc.*
#service mongodb start
service mongodb restart




