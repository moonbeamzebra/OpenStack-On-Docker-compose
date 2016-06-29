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
HEAT_HOST=10.10.10.10
MONGO_HOST=10.10.10.10
CEIL_HOST=10.10.10.10
MYSQLHOST=10.10.10.10
REGION1=RegionOne

CMP1_MANAGEMENT_INTERFACE_IP_ADDRESS=10.10.10.11
NEUTRON_HOST=$CMP1_MANAGEMENT_INTERFACE_IP_ADDRESS
NET_OVERLAY_INTERFACE_IP_ADDRESS=10.10.11.11
NET_PROVIDER_INTERFACE_NAME=eth2

## Get the packages
apt-get install software-properties-common -y
add-apt-repository cloud-archive:mitaka -y


#apt-get update && apt-get dist-upgrade -y
apt-get update -y
apt-get -y install crudini curl \
mariadb-client-5.* \
python-mysqldb


cat <<EOF > /admin-openrc.sh
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_AUTH_URL=http://$KEYSTONE_HOST:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

cat <<EOF > /demo-openrc.sh
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=demo
export OS_TENANT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=$DEMO_PASS
export OS_AUTH_URL=http://$KEYSTONE_HOST:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF


source /admin-openrc.sh

echo "DROP DATABASE IF EXISTS neutron;
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' \
  IDENTIFIED BY '$NEUTRON_DBPASS';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' \
  IDENTIFIED BY '$NEUTRON_DBPASS';
FLUSH PRIVILEGES;" | mysql --user=root --password=$MYSQL_ROOT_PASSWORD -h $MYSQLHOST -P 3306

openstack user create --domain default --password $NEUTRON_PASS neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron \
  --description "OpenStack Networking" network
openstack endpoint create --region $REGION1 \
  network public http://$NEUTRON_HOST:9696
openstack endpoint create --region $REGION1 \
  network internal http://$NEUTRON_HOST:9696
openstack endpoint create --region $REGION1 \
  network admin http://$NEUTRON_HOST:9696

apt-get install -y \
neutron-server \
neutron-plugin-ml2 \
neutron-linuxbridge-agent \
neutron-l3-agent \
neutron-dhcp-agent \
neutron-metadata-agent \
python-memcache

cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bak
crudini --set /etc/neutron/neutron.conf database connection mysql+pymysql://neutron:$NEUTRON_DBPASS@$MYSQLHOST/neutron

crudini --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
crudini --set /etc/neutron/neutron.conf DEFAULT service_plugins router
crudini --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips True

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

crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True
#crudini --set /etc/neutron/neutron.conf DEFAULT nova_url http://$NOVA_HOST:8774/v2

crudini --set /etc/neutron/neutron.conf nova auth_url http://$KEYSTONE_HOST:35357
crudini --set /etc/neutron/neutron.conf nova auth_plugin password
crudini --set /etc/neutron/neutron.conf nova project_domain_name default
crudini --set /etc/neutron/neutron.conf nova user_domain_name default
crudini --set /etc/neutron/neutron.conf nova region_name $REGION1
crudini --set /etc/neutron/neutron.conf nova project_name service
crudini --set /etc/neutron/neutron.conf nova username nova
crudini --set /etc/neutron/neutron.conf nova password $NOVA_PASS

crudini --set /etc/neutron/neutron.conf DEFAULT verbose True

diff /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bak

sleep 5

cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.bak
#crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,vxlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vxlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers linuxbridge,l2population
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks provider
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000

crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True

diff /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.bak

sleep 5

cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.bak
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings provider:$NET_PROVIDER_INTERFACE_NAME
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan True
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan local_ip $NET_OVERLAY_INTERFACE_IP_ADDRESS
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan l2_population True

crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group True
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

diff /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.bak

sleep 5

cp /etc/neutron/l3_agent.ini /etc/neutron/l3_agent.ini.bak
crudini --set /etc/neutron/l3_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.BridgeInterfaceDriver
crudini --set /etc/neutron/l3_agent.ini DEFAULT external_network_bridge ""
diff /etc/neutron/l3_agent.ini /etc/neutron/l3_agent.ini.bak

cp /etc/neutron/dhcp_agent.ini  /etc/neutron/dhcp_agent.ini.bak
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.BridgeInterfaceDriver
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata True
diff /etc/neutron/dhcp_agent.ini  /etc/neutron/dhcp_agent.ini.bak

echo "dhcp-option-force=26,1450" >> /etc/neutron/dnsmasq-neutron.conf

sleep 5

cp /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.bak
crudini --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip $NOVA_HOST
crudini --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret $METADATA_SECRET
crudini --set /etc/neutron/metadata_agent.ini DEFAULT verbose True

#crudini --set /etc/neutron/metadata_agent.ini DEFAULT auth_uri http://$KEYSTONE_HOST:5000
#crudini --set /etc/neutron/metadata_agent.ini DEFAULT auth_url http://$KEYSTONE_HOST:35357
#crudini --set /etc/neutron/metadata_agent.ini DEFAULT auth_region $REGION1
#crudini --set /etc/neutron/metadata_agent.ini DEFAULT auth_plugin password
#crudini --set /etc/neutron/metadata_agent.ini DEFAULT project_domain_id default
#crudini --set /etc/neutron/metadata_agent.ini DEFAULT user_domain_id default
#crudini --set /etc/neutron/metadata_agent.ini DEFAULT project_name service
#crudini --set /etc/neutron/metadata_agent.ini DEFAULT username neutron
#crudini --set /etc/neutron/metadata_agent.ini DEFAULT password $NEUTRON_PASS

diff /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.bak

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

service neutron-server restart
service neutron-linuxbridge-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service neutron-l3-agent restart
