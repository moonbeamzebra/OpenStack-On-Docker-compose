#! /bin/bash +ex

service neutron-server restart

touch /var/log/neutron/neutron-server2.log
tail -f /var/log/neutron/neutron-server2.log
