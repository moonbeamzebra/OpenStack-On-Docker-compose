#! /bin/bash

if [ -f /setup.done ];
then
   echo "Setup done" > /tmp/done
   exit 0
fi

cat <<EOF > /admin-openrc.sh
export OS_PROJECT_DOMAIN_ID=default
export OS_USER_DOMAIN_ID=default
export OS_PROJECT_NAME=admin
export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_AUTH_URL=http://$KEYSTONE_HOST:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

cat <<EOF > /demo-openrc.sh
export OS_PROJECT_DOMAIN_ID=default
export OS_USER_DOMAIN_ID=default
export OS_PROJECT_NAME=demo
export OS_TENANT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=$DEMO_PASS
export OS_AUTH_URL=http://$KEYSTONE_HOST:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

service nova-compute stop
service neutron-plugin-openvswitch-agent stop

./wait_for_rabbitmq.sh


cp /etc/sysctl.conf /etc/sysctl.conf.bak
cat <<EOF >> /etc/sysctl.conf
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.all.rp_filter=0
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
EOF
sysctl -p

cp /etc/nova/nova.conf /etc/nova/nova.conf.bak
crudini --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit
crudini --set /etc/nova/nova.conf DEFAULT auth_strategy keystone
crudini --set /etc/nova/nova.conf DEFAULT my_ip $CMP1_MANAGEMENT_INTERFACE_IP_ADDRESS
crudini --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API
crudini --set /etc/nova/nova.conf DEFAULT security_group_api neutron
crudini --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
crudini --set /etc/nova/nova.conf DEFAULT verbose True

crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_host $RABBIT_HOST
crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_userid $RABBITMQ_DEFAULT_USER
crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_password $RABBITMQ_DEFAULT_PASS

crudini --set /etc/nova/nova.conf keystone_authtoken auth_uri http://$KEYSTONE_HOST:5000
crudini --set /etc/nova/nova.conf keystone_authtoken auth_url http://$KEYSTONE_HOST:35357
crudini --set /etc/nova/nova.conf keystone_authtoken auth_plugin password
crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_id default
crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_id default
crudini --set /etc/nova/nova.conf keystone_authtoken project_name service
crudini --set /etc/nova/nova.conf keystone_authtoken username nova
crudini --set /etc/nova/nova.conf keystone_authtoken password $NOVA_PASS

crudini --set /etc/nova/nova.conf vnc enabled True
crudini --set /etc/nova/nova.conf vnc vncserver_listen 0.0.0.0
crudini --set /etc/nova/nova.conf vnc vncserver_proxyclient_address $CMP1_MANAGEMENT_INTERFACE_IP_ADDRESS
crudini --set /etc/nova/nova.conf vnc novncproxy_base_url http://$NOVA_HOST:6080/vnc_auto.html

crudini --set /etc/nova/nova.conf glance host $GLANCE_HOST

crudini --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

crudini --set /etc/nova/nova.conf neutron url http://$NEUTRON_HOST:9696
crudini --set /etc/nova/nova.conf neutron auth_url http://$KEYSTONE_HOST:35357
crudini --set /etc/nova/nova.conf neutron auth_plugin password
crudini --set /etc/nova/nova.conf neutron project_domain_id default
crudini --set /etc/nova/nova.conf neutron user_domain_id default
crudini --set /etc/nova/nova.conf neutron region_name $REGION1
crudini --set /etc/nova/nova.conf neutron project_name service
crudini --set /etc/nova/nova.conf neutron username neutron
crudini --set /etc/nova/nova.conf neutron password $NEUTRON_PASS

diff /etc/nova/nova.conf /etc/nova/nova.conf.bak

rm -f /var/lib/nova/nova.sqlite

cp /etc/neutron/neutron.conf  /etc/neutron/neutron.conf .bak
crudini --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
crudini --set /etc/neutron/neutron.conf DEFAULT service_plugins router
crudini --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips True

crudini --set /etc/neutron/neutron.conf DEFAULT rpc_backend rabbit
crudini --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
crudini --set /etc/neutron/neutron.conf DEFAULT verbose True

crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_host $RABBIT_HOST
crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_userid $RABBITMQ_DEFAULT_USER
crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_password $RABBITMQ_DEFAULT_PASS

crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://$KEYSTONE_HOST:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://$KEYSTONE_HOST:35357
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_plugin password
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_domain_id default
crudini --set /etc/neutron/neutron.conf keystone_authtoken user_domain_id default
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set /etc/neutron/neutron.conf keystone_authtoken username neutron
crudini --set /etc/neutron/neutron.conf keystone_authtoken password $NEUTRON_PASS
diff /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bak

cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.bak
#crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,vxlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vxlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch,l2population
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks external
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000

crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver

crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs local_ip $CMP1_OVERLAY_INTERFACE_IP_ADDRESS
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs enable_tunneling True
#crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs bridge_mappings vlan:br-vlan

crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini agent tunnel_types vxlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini agent l2_population True

crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True


diff /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.bak


touch /setup.done
