#! /bin/bash +ex

./wait_for_rabbitmq.sh

touch /var/log/openvswitch/ovs-ctl.log
touch /var/log/openvswitch/ovsdb-server.log
touch /var/log/openvswitch/ovs-vswitchd.log


touch /var/log/neutron/dhcp-agent.log
touch /var/log/neutron/ovs-cleanup.log
touch /var/log/neutron/neutron-metadata-agent.log
touch /var/log/neutron/openvswitch-agent.log
touch /var/log/neutron/l3-agent.log
chown neutron: /var/log/neutron/*

service openvswitch-switch restart
service neutron-plugin-openvswitch-agent restart
service neutron-l3-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart

sleep 5

tail -v -F /var/log/openvswitch/ovs-ctl.log &
tail -v -F /var/log/openvswitch/ovsdb-server.log &
tail -v -F /var/log/openvswitch/ovs-vswitchd.log &

tail -v -F /var/log/neutron/dhcp-agent.log &
tail -v -F /var/log/neutron/ovs-cleanup.log &
tail -v -F /var/log/neutron/neutron-metadata-agent.log &
tail -v -F /var/log/neutron/openvswitch-agent.log &

## Blocking one
tail -v -F /var/log/neutron/l3-agent.log
