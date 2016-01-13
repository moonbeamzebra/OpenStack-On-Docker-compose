#! /bin/bash
echo "$CEIL_PASS"
mongo --host $MONGO_HOST --eval 'db = db.getSiblingDB("ceilometer");db.addUser({user: "ceilometer",pwd: "$CEIL_PASS",roles: [ "readWrite", "dbAdmin" ]})'


