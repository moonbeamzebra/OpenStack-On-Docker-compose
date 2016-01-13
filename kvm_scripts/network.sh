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
MY_TUNNEL_IP="10.199.5.168"


## Get the packages
apt-get install ubuntu-cloud-keyring
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu" "trusty-updates/kilo main" > /etc/apt/sources.list.d/cloudarchive-kilo.list
apt-get update
apt-get -y install crudini

cat <<EOF >> /etc/sysctl.conf
net.ipv4.ip_forward=1
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
EOF

sysctl -p

apt-get install -y neutron-plugin-ml2 neutron-plugin-openvswitch-agent neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent

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
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks external
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_gre tunnel_id_ranges 1:1000
#crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vlan network_vlan_ranges physnetVlans:2:1999,physnetVlans:2200:4094
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs local_ip $MY_TUNNEL_IP
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs enable_tunneling True
#crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs bridge_mappings external:br-ex,physnetVlans:br-physnetVlans
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs bridge_mappings external:br-ex
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini agent tunnel_types gre

cp /etc/neutron/l3_agent.ini /etc/neutron/l3_agent.ini.bak
crudini --set /etc/neutron/l3_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
crudini --set /etc/neutron/l3_agent.ini DEFAULT use_namespaces True
crudini --set /etc/neutron/l3_agent.ini DEFAULT external_network_bridge
crudini --set /etc/neutron/l3_agent.ini DEFAULT router_delete_namespaces True
crudini --set /etc/neutron/l3_agent.ini DEFAULT verbose True

cp /etc/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini.bak
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_delete_namespaces True
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dnsmasq_config_file /etc/neutron/dnsmasq-neutron.conf
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp-option-force 26,1454
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT verbose True

cp /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.bak
crudini --set /etc/neutron/metadata_agent.ini DEFAULT auth_uri http://$KEYSTONE_HOST:5000
crudini --set /etc/neutron/metadata_agent.ini DEFAULT auth_url http://$KEYSTONE_HOST:35357
crudini --set /etc/neutron/metadata_agent.ini DEFAULT auth_region $REGION1
crudini --set /etc/neutron/metadata_agent.ini DEFAULT auth_plugin password
crudini --set /etc/neutron/metadata_agent.ini DEFAULT project_domain_id default 
crudini --set /etc/neutron/metadata_agent.ini DEFAULT user_domain_id default
crudini --set /etc/neutron/metadata_agent.ini DEFAULT project_name service
crudini --set /etc/neutron/metadata_agent.ini DEFAULT username neutron
crudini --set /etc/neutron/metadata_agent.ini DEFAULT password $NEUTRON_PASS
crudini --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip $NOVA_HOST
crudini --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret $NEUTRON_PASS
crudini --set /etc/neutron/metadata_agent.ini DEFAULT verbose True

diff /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bak
diff /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.bak
diff /etc/neutron/l3_agent.ini /etc/neutron/l3_agent.ini.bak
diff /etc/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini.bak
diff /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.bak

echo "dhcp-option-force=26,1454" > /etc/neutron/dnsmasq-neutron.conf

pkill dnsmasq

service openvswitch-switch restart
ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex eth2
#ovs-vsctl add-br br-physnetVlans
#ovs-vsctl add-port br-physnetVlans eth3

service neutron-plugin-openvswitch-agent restart
service neutron-l3-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart