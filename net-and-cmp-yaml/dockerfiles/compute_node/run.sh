#! /bin/bash +ex

./wait_for_rabbitmq.sh

touch /tmp/log.log

service nova-compute restart

service neutron-plugin-openvswitch-agent restart

sleep 5


## Blocking one
tail -v -F /tmp/log.log
