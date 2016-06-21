#! /bin/bash -x

MYSQL_ROOT_PASSWORD=mysql1
KEYSTONE_DBPASS=keystonedb1
CINDER_DBPASS=cinderdb1
GLANCE_DBPASS=glancedb1
NOVA_DBPASS=novadb1
NEUTRON_DBPASS=neutrondb1
HEAT_DBPASS=heatdb1
ADMIN_PASS=osu1
RABBITMQ_DEFAULT_USER=openstack
RABBITMQ_DEFAULT_PASS=rabbit1
CINDER_PASS=cinder1
GLANCE_PASS=glance1
NOVA_PASS=nova1
NEUTRON_PASS=neutron1
HEAT_PASS=heat1
CEIL_PASS=lab1
DEMO_PASS=demo
METADATA_SECRET=metadata_secret1
RABBIT_HOST=10.10.10.10
KEYSTONE_HOST=10.10.10.10
HORIZON_HOST=10.10.10.10
CINDER_HOST=10.10.10.10
GLANCE_HOST=10.10.10.10
NOVA_HOST=10.10.10.10
NEUTRON_HOST=10.10.10.10
HEAT_HOST=10.10.10.10
MONGO_HOST=10.10.10.10
CEIL_HOST=10.10.10.10
MYSQLHOST=10.10.10.10
REGION1=RegionOne
CMP1_MANAGEMENT_INTERFACE_IP_ADDRESS=10.10.10.12
NET_OVERLAY_INTERFACE_IP_ADDRESS=10.10.11.11
CMP1_OVERLAY_INTERFACE_IP_ADDRESS=10.10.11.12
NET_PUBLIC_INTERFACE_NAME=eth2
CMP1_PUBLIC_INTERFACE_NAME=eth2


## Get the packages
apt-get install software-properties-common -y
add-apt-repository cloud-archive:mitaka -y

#apt-get update && apt-get dist-upgrade -y
apt-get update -y
apt-get -y install crudini curl


apt-get install -y \
                   nova-compute \
                   sysfsutils \
                   ceilometer-agent-compute \
                   python-memcache


cp /etc/nova/nova.conf /etc/nova/nova.conf.bak
crudini --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit
crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_host $RABBIT_HOST
crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_userid $RABBITMQ_DEFAULT_USER
crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_password $RABBITMQ_DEFAULT_PASS

crudini --set /etc/nova/nova.conf DEFAULT auth_strategy keystone
crudini --set /etc/nova/nova.conf keystone_authtoken auth_uri http://$KEYSTONE_HOST:5000
crudini --set /etc/nova/nova.conf keystone_authtoken auth_url http://$KEYSTONE_HOST:35357
crudini --set /etc/nova/nova.conf keystone_authtoken memcached_servers $KEYSTONE_HOST:11211
crudini --set /etc/nova/nova.conf keystone_authtoken auth_type password
crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_name default
crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_name default
crudini --set /etc/nova/nova.conf keystone_authtoken project_name service
crudini --set /etc/nova/nova.conf keystone_authtoken username nova
crudini --set /etc/nova/nova.conf keystone_authtoken password $NOVA_PASS

crudini --set /etc/nova/nova.conf DEFAULT my_ip $CMP1_MANAGEMENT_INTERFACE_IP_ADDRESS

crudini --set /etc/nova/nova.conf DEFAULT use_neutron True
crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
crudini --set /etc/nova/nova.conf DEFAULT verbose True

crudini --set /etc/nova/nova.conf vnc enabled True
crudini --set /etc/nova/nova.conf vnc vncserver_listen 0.0.0.0
crudini --set /etc/nova/nova.conf vnc vncserver_proxyclient_address $CMP1_MANAGEMENT_INTERFACE_IP_ADDRESS
crudini --set /etc/nova/nova.conf vnc novncproxy_base_url http://$NOVA_HOST:6080/vnc_auto.html

crudini --set /etc/nova/nova.conf glance api_servers = http://$GLANCE_HOST:9292

crudini --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

crudini --set /etc/nova/nova.conf neutron url http://$NEUTRON_HOST:9696
crudini --set /etc/nova/nova.conf neutron auth_url http://$KEYSTONE_HOST:35357
crudini --set /etc/nova/nova.conf neutron auth_type password
crudini --set /etc/nova/nova.conf neutron project_domain_name default
crudini --set /etc/nova/nova.conf neutron user_domain_name default
crudini --set /etc/nova/nova.conf neutron region_name $REGION1
crudini --set /etc/nova/nova.conf neutron project_name service
crudini --set /etc/nova/nova.conf neutron username neutron
crudini --set /etc/nova/nova.conf neutron password $NEUTRON_PASS


# Following 3 not documented as such
crudini --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API
crudini --set /etc/nova/nova.conf DEFAULT security_group_api neutron
crudini --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver

# Next for ceilometer
crudini --set /etc/nova/nova.conf DEFAULT instance_usage_audit True
crudini --set /etc/nova/nova.conf DEFAULT instance_usage_audit_period hour
crudini --set /etc/nova/nova.conf DEFAULT notify_on_state_change vm_and_task_state
crudini --set /etc/nova/nova.conf DEFAULT notification_driver messagingv2

diff /etc/nova/nova.conf /etc/nova/nova.conf.bak

# Next for ceilometer
cp /etc/ceilometer/ceilometer.conf /etc/ceilometer/ceilometer.conf.bak
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT rpc_backend rabbit
crudini --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_host $RABBIT_HOST
crudini --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_userid $RABBITMQ_DEFAULT_USER
crudini --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_password $RABBITMQ_DEFAULT_PASS

crudini --set /etc/ceilometer/ceilometer.conf DEFAULT auth_strategy keystone
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_uri http://$KEYSTONE_HOST:5000
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_url http://$KEYSTONE_HOST:35357
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken memcached_servers $KEYSTONE_HOST:11211
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_type password
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken project_domain_name default
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken user_domain_name default
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken project_name service
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken username ceilometer
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken password $CEIL_PASS
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_auth_url http://$KEYSTONE_HOST:5000/v2.0
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_username ceilometer
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_tenant_name service
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_password $CEIL_PASS
crudini --set /etc/ceilometer/ceilometer.conf service_credentials interface internalURL
crudini --set /etc/ceilometer/ceilometer.conf service_credentials region_name $REGION1
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT verbose True

diff /etc/ceilometer/ceilometer.conf /etc/ceilometer/ceilometer.conf.bak


service nova-compute restart
rm -f /var/lib/nova/nova.sqlite

cat <<EOF >> /etc/sysctl.conf
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.all.rp_filter=0
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
EOF


sysctl -p

apt-get install -y neutron-plugin-ml2 neutron-plugin-openvswitch-agent

cp /etc/neutron/neutron.conf  /etc/neutron/neutron.conf.bak
crudini --set /etc/neutron/neutron.conf DEFAULT rpc_backend rabbit
crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_host $RABBIT_HOST
crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_userid $RABBITMQ_DEFAULT_USER
crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_password $RABBITMQ_DEFAULT_PASS

crudini --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://$KEYSTONE_HOST:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://$KEYSTONE_HOST:35357
crudini --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers $KEYSTONE_HOST:11211
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
crudini --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set /etc/neutron/neutron.conf keystone_authtoken username neutron
crudini --set /etc/neutron/neutron.conf keystone_authtoken password $NEUTRON_PASS

crudini --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
crudini --set /etc/neutron/neutron.conf DEFAULT service_plugins router
crudini --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips True

crudini --set /etc/neutron/neutron.conf DEFAULT verbose True


diff /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bak

sleep 5

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

sleep 5

service ceilometer-agent-compute restart

service nova-compute restart

service neutron-openvswitch-agent restart
