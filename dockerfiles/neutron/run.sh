#! /bin/bash +ex


./wait_for_rabbitmq.sh

service neutron-server restart

touch /var/log/neutron/neutron-server2.log
tail -f /var/log/neutron/neutron-server2.log
