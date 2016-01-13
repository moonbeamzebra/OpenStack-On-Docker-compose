#! /bin/bash +ex
export NOVA_ETH_IP=`ifconfig eth0 | grep "inet addr" | tr : '\t' | tr [:space:] '\t' | cut -f 13`
crudini --set /etc/nova/nova.conf DEFAULT my_ip $NOVA_ETH_IP
crudini --set /etc/nova/nova.conf DEFAULT vncserver_listen $NOVA_ETH_IP
crudini --set /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address $NOVA_ETH_IP


service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart


tail -f /var/log/nova/*.log
