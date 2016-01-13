#! /bin/bash -x

RABBITMQ_DEFAULT_USER="openstack"
RABBITMQ_DEFAULT_PASS="rabbit1"
GLANCE_PASS="glance1"
NOVA_PASS="nova1"
NEUTRON_PASS="neutron1"
HEAT_PASS="heat1"
CEIL_PASS="lab1"
DEMO_PASS="demo"
RABBIT_HOST="10.199.1.26"
KEYSTONE_HOST="10.199.1.26"
HORIZON_HOST="10.199.1.26"
GLANCE_HOST="10.199.1.26"
NOVA_HOST="10.199.1.26"
NEUTRON_HOST="10.199.1.26"
HEAT_HOST="10.199.1.26"
MONGO_HOST="10.199.1.26"
CEIL_HOST="10.199.1.26"
MYSQLHOST="10.199.1.26"
REGION1="RegionOne"

MY_IP="10.199.1.28"
MY_TUNNEL_IP="10.199.5.169"

## Get the packages
apt-get install ubuntu-cloud-keyring
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu" "trusty-updates/kilo main" > /etc/apt/sources.list.d/cloudarchive-kilo.list
apt-get update
apt-get -y install crudini

apt-get install -y nova-compute sysfsutils

cp /etc/nova/nova.conf /etc/nova/nova.conf.bak
crudini --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit
crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_host $RABBIT_HOST
crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_userid $RABBITMQ_DEFAULT_USER
crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_password $RABBITMQ_DEFAULT_PASS
crudini --set /etc/nova/nova.conf DEFAULT auth_strategy keystone
crudini --set /etc/nova/nova.conf keystone_authtoken auth_uri http://$KEYSTONE_HOST:5000
crudini --set /etc/nova/nova.conf keystone_authtoken auth_url http://$KEYSTONE_HOST:35357
crudini --set /etc/nova/nova.conf keystone_authtoken auth_plugin password
crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_id default 
crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_id default
crudini --set /etc/nova/nova.conf keystone_authtoken project_name service
crudini --set /etc/nova/nova.conf keystone_authtoken username nova
crudini --set /etc/nova/nova.conf keystone_authtoken password $NOVA_PASS
crudini --set /etc/nova/nova.conf DEFAULT my_ip $MY_IP
crudini --set /etc/nova/nova.conf DEFAULT vnc_enabled True
crudini --set /etc/nova/nova.conf DEFAULT vncserver_listen 0.0.0.0
crudini --set /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address $MY_IP
crudini --set /etc/nova/nova.conf DEFAULT novncproxy_base_url http://$NOVA_HOST:6080/vnc_auto.html
crudini --set /etc/nova/nova.conf DEFAULT verbose True
crudini --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lock/nova
crudini --set /etc/nova/nova.conf glance host $GLANCE_HOST
crudini --set /etc/nova/nova.conf libvirt live_migration_uri qemu+tcp://%s/system
crudini --set /etc/nova/nova.conf libvirt live_migration_flag VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE 
diff /etc/nova/nova.conf /etc/nova/nova.conf.bak

echo "listen_tls = 0" >> /etc/libvirt/libvirtd.conf
echo "listen_tcp = 1" >> /etc/libvirt/libvirtd.conf
echo 'auth_tcp = "none"' >> /etc/libvirt/libvirtd.conf

sed -i "s/libvirtd_opts=\"-d\"/libvirtd_opts=\" -d -l\"/g" /etc/default/libvirt-bin

sleep 5

service libvirt-bin restart
service nova-compute restart
rm -f /var/lib/nova/nova.sqlite

cat <<EOF >> /etc/sysctl.conf
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
EOF

sysctl -p

apt-get install -y neutron-plugin-ml2 neutron-plugin-openvswitch-agent

cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bak
crudini --set /etc/neutron/neutron.conf DEFAULT rpc_backend rabbit
crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_host $RABBIT_HOST
crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_userid $RABBITMQ_DEFAULT_USER
crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_password $RABBITMQ_DEFAULT_PASS
crudini --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://$KEYSTONE_HOST:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://$KEYSTONE_HOST:35357
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_plugin password
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_domain_id default 
crudini --set /etc/neutron/neutron.conf keystone_authtoken user_domain_id default
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set /etc/neutron/neutron.conf keystone_authtoken username neutron
crudini --set /etc/neutron/neutron.conf keystone_authtoken password $NEUTRON_PASS
sed -i "s/auth_host/#auth_host/g" /etc/neutron/neutron.conf
sed -i "s/auth_port/#auth_port/g" /etc/neutron/neutron.conf
sed -i "s/auth_protocol/#auth_protocol/g" /etc/neutron/neutron.conf
crudini --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
crudini --set /etc/neutron/neutron.conf DEFAULT service_plugins router
crudini --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips True
crudini --set /etc/neutron/neutron.conf DEFAULT verbose True

cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.bak
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,gre,vxlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types gre,vlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_gre tunnel_id_ranges 1:1000
#crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vlan physnetVlans:2:1999,physnetVlans:2200:4094
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs local_ip $MY_TUNNEL_IP
#crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs bridge_mappings external:br-ex,physnetVlans:br-physnetVlans
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs bridge_mappings external:br-ex
#crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs enable_tunneling True
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini agent tunnel_types gre

diff /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bak
diff /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.bak

sleep 5

service openvswitch-switch restart

cp /etc/nova/nova.conf /etc/nova/nova.conf.bak 
crudini --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API
crudini --set /etc/nova/nova.conf DEFAULT security_group_api neutron
crudini --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
crudini --set /etc/nova/nova.conf neutron url http://$NEUTRON_HOST:9696
crudini --set /etc/nova/nova.conf neutron auth_strategy keystone
crudini --set /etc/nova/nova.conf neutron admin_auth_url http://$KEYSTONE_HOST:35357/v2.0
crudini --set /etc/nova/nova.conf neutron admin_tenant_name service
crudini --set /etc/nova/nova.conf neutron admin_username neutron
crudini --set /etc/nova/nova.conf neutron admin_password $NEUTRON_PASS

diff /etc/nova/nova.conf /etc/nova/nova.conf.bak 

sleep 5

#ovs-vsctl add-br br-physnetVlans
#ovs-vsctl add-port br-physnetVlans bond0


sleep 5

service nova-compute restart
service neutron-plugin-openvswitch-agent restart

#apt-get install -y ceilometer-agent-compute

#cp /etc/ceilometer/ceilometer.conf /etc/ceilometer/ceilometer.conf.bak
#crudini --set /etc/ceilometer/ceilometer.conf database connection mongodb://ceilometer:lab1@$REGION_CONTROLLER_MANAGEMENT_IP:27017/ceilometer
#crudini --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_host $REGION_CONTROLLER_MANAGEMENT_IP
#crudini --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_userid openstack
#crudini --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_password $RABBITMQ_DEFAULT_PASS
#crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_uri http://$CONTROLLER_MANAGEMENT_IP:5000/v2.0
#crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken identity_uri http://$CONTROLLER_MANAGEMENT_IP:35357
#crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken admin_tenant_name service
#crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken admin_user ceilometer
#crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken admin_password $CEIL_PASS
#crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_auth_url http://$CONTROLLER_MANAGEMENT_IP:5000/v2.0
#crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_username ceilometer
#crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_tenant_name service
#crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_password $CEIL_PASS
#crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_endpoint_type internalURL
#crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_region_name $REGION1
#crudini --set /etc/ceilometer/ceilometer.conf publisher telemetry_secret $CEIL_PASS
#crudini --set /etc/ceilometer/ceilometer.conf DEFAULT verbose True
#diff /etc/ceilometer/ceilometer.conf /etc/ceilometer/ceilometer.conf.bak

#sleep 5

#cp /etc/nova/nova.conf /etc/nova/nova.conf.bak 
#crudini --set /etc/nova/nova.conf DEFAULT instance_usage_audit True
#crudini --set /etc/nova/nova.conf DEFAULT instance_usage_audit_period hour
#crudini --set /etc/nova/nova.conf DEFAULT notify_on_state_change vm_and_task_state
#crudini --set /etc/nova/nova.conf DEFAULT notification_driver messagingv2
#diff /etc/nova/nova.conf /etc/nova/nova.conf.bak 

#sleep 5

#service ceilometer-agent-compute restart
service nova-compute restart
