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
RABBIT_HOST=10.199.1.26
KEYSTONE_HOST=10.199.1.26
HORIZON_HOST=10.199.1.26
CINDER_HOST=10.199.1.26
GLANCE_HOST=10.199.1.26
NOVA_HOST=10.199.1.26
NEUTRON_HOST=10.199.1.26
HEAT_HOST=10.199.1.26
MONGO_HOST=10.199.1.26
CEIL_HOST=10.199.1.26
MYSQLHOST=10.199.1.26
REGION1=RegionOne
NET_PUBLIC_INTERFACE_NAME=eth1

## Get the packages
apt-get install software-properties-common -y
add-apt-repository cloud-archive:liberty -y


#apt-get update && apt-get dist-upgrade -y
apt-get update -y
apt-get -y install crudini curl


apt-get install -y python-openstackclient mariadb-client-5.* python-mysqldb


## Setup mysql

#/etc/mysql/conf.d/mysqld_openstack.cnf
## Setup mysql
#apt-get install -y mariadb-server python-mysqldb
#sed -i.bak "s/bind-address/#bind-address/g" /etc/mysql/my.cnf
#sed -i "/\[mysqld\]/a \
#bind-address = $MYSQLHOST\n\
#default-storage-engine = innodb\n\
#innodb_file_per_table\n\
#collation-server = utf8_general_ci\n\
#init-connect = 'SET NAMES utf8'\n\
#character-set-server = utf8\n\
#" /etc/mysql/my.cnf
#diff /etc/mysql/my.cnf /etc/mysql/my.cnf.bak

#sleep 5

#service mysql restart

## Set up rabbit_mq
apt-get install -y rabbitmq-server
rabbitmqctl add_user $RABBITMQ_DEFAULT_USER $RABBITMQ_DEFAULT_PASS
rabbitmqctl set_permissions $RABBITMQ_DEFAULT_USER ".*" ".*" ".*"

sleep 5

service rabbitmq-server restart


## Set up keystone
echo "CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$KEYSTONE_DBPASS';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$KEYSTONE_DBPASS';
FLUSH PRIVILEGES;" | mysql --user=root --password=$MYSQL_ROOT_PASSWORD -h $MYSQLHOST -P 3306

apt-get install -y openssl
ADMIN_TOKEN=$(openssl rand -hex 10)
echo "Admin token: $ADMIN_TOKEN"

echo "manual" > /etc/init/keystone.override

apt-get install -y keystone apache2 libapache2-mod-wsgi memcached python-memcache

cp /etc/keystone/keystone.conf /etc/keystone/keystone.conf.bak
crudini --set /etc/keystone/keystone.conf DEFAULT admin_token $ADMIN_TOKEN
crudini --set /etc/keystone/keystone.conf DEFAULT verbose True
crudini --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:$KEYSTONE_DBPASS@$MYSQLHOST/keystone
crudini --set /etc/keystone/keystone.conf token provider uuid
crudini --set /etc/keystone/keystone.conf token driver memcache
crudini --set /etc/keystone/keystone.conf revoke driver sql
crudini --set /etc/keystone/keystone.conf memcache servers localhost:11211
diff /etc/keystone/keystone.conf /etc/keystone/keystone.conf.bak

sleep 5

su -s /bin/sh -c "keystone-manage db_sync" keystone

cat <<EOF > /etc/apache2/sites-available/wsgi-keystone.conf
Listen 5000
Listen 35357

<VirtualHost *:5000>
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-public
    WSGIScriptAlias / /usr/bin/keystone-wsgi-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    <IfVersion >= 2.4>
      ErrorLogFormat "%{cu}t %M"
    </IfVersion>
    ErrorLog /var/log/apache2/keystone.log
    CustomLog /var/log/apache2/keystone_access.log combined

    <Directory /usr/bin>
        <IfVersion >= 2.4>
            Require all granted
        </IfVersion>
        <IfVersion < 2.4>
            Order allow,deny
            Allow from all
        </IfVersion>
    </Directory>
</VirtualHost>

<VirtualHost *:35357>
    WSGIDaemonProcess keystone-admin processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-admin
    WSGIScriptAlias / /usr/bin/keystone-wsgi-admin
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    <IfVersion >= 2.4>
      ErrorLogFormat "%{cu}t %M"
    </IfVersion>
    ErrorLog /var/log/apache2/keystone.log
    CustomLog /var/log/apache2/keystone_access.log combined

    <Directory /usr/bin>
        <IfVersion >= 2.4>
            Require all granted
        </IfVersion>
        <IfVersion < 2.4>
            Order allow,deny
            Allow from all
        </IfVersion>
    </Directory>
</VirtualHost>
EOF

ln -s /etc/apache2/sites-available/wsgi-keystone.conf /etc/apache2/sites-enabled

service apache2 restart
rm -f /var/lib/keystone/keystone.db

sleep 5

export OS_TOKEN=$ADMIN_TOKEN
export OS_URL=http://$KEYSTONE_HOST:35357/v3
export OS_IDENTITY_API_VERSION=3

openstack service create \
  --name keystone --description "OpenStack Identity" identity
  
openstack endpoint create --region $REGION1 \
  identity public http://$KEYSTONE_HOST:5000/v2.0
openstack endpoint create --region $REGION1 \
  identity internal http://$KEYSTONE_HOST:5000/v2.0   
openstack endpoint create --region $REGION1 \
  identity admin http://$KEYSTONE_HOST:35357/v2.0   
openstack project create --domain default \
  --description "Admin Project" admin
openstack user create  --domain default --password $ADMIN_PASS admin
openstack role create admin
openstack role add --project admin --user admin admin
openstack project create --domain default \
  --description "Service Project" service
openstack project create --domain default \
  --description "Demo Project" demo
openstack user create  --domain default --password $DEMO_PASS demo
openstack role create user
openstack role add --project demo --user demo user


cp /etc/keystone/keystone-paste.ini /etc/keystone/keystone-paste.ini.bak
crudini --del /etc/keystone/keystone-paste.ini pipeline:public_api admin_token_auth
crudini --del /etc/keystone/keystone-paste.ini pipeline:admin_api admin_token_auth
crudini --del /etc/keystone/keystone-paste.ini pipeline:api_v3 admin_token_auth
diff /etc/keystone/keystone-paste.ini /etc/keystone/keystone-paste.ini.bak

sleep 5

unset OS_TOKEN OS_URL


cat <<EOF > ~/admin-openrc.sh
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

cat <<EOF > ~/demo-openrc.sh
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

source ~/admin-openrc.sh

echo "CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$GLANCE_DBPASS';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$GLANCE_DBPASS';
FLUSH PRIVILEGES;" | mysql --user=root --password=$MYSQL_ROOT_PASSWORD -h $MYSQLHOST -P 3306

openstack user create --domain default --password $GLANCE_PASS glance
openstack role add --project service --user glance admin
openstack service create --name glance \
  --description "OpenStack Image service" image
openstack endpoint create --region $REGION1 \
  image public http://$GLANCE_HOST:9292
openstack endpoint create --region $REGION1 \
  image internal http://$GLANCE_HOST:9292
openstack endpoint create --region $REGION1 \
  image admin http://$GLANCE_HOST:9292  

apt-get install -y glance python-glanceclient



cp /etc/glance/glance-api.conf /etc/glance/glance-api.conf.bak
crudini --set /etc/glance/glance-api.conf database connection mysql+pymysql://glance:$GLANCE_DBPASS@$MYSQLHOST/glance

crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_uri http://$KEYSTONE_HOST:5000
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_url http://$KEYSTONE_HOST:35357
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_plugin password
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_domain_id default 
crudini --set /etc/glance/glance-api.conf keystone_authtoken user_domain_id default
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_name service
crudini --set /etc/glance/glance-api.conf keystone_authtoken username glance
crudini --set /etc/glance/glance-api.conf keystone_authtoken password $GLANCE_PASS

crudini --set /etc/glance/glance-api.conf paste_deploy flavor keystone

crudini --set /etc/glance/glance-api.conf glance_store default_store file
crudini --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images/

crudini --set /etc/glance/glance-api.conf DEFAULT notification_driver noop
crudini --set /etc/glance/glance-api.conf DEFAULT verbose True


cp /etc/glance/glance-registry.conf  /etc/glance/glance-registry.conf.bak

crudini --set /etc/glance/glance-registry.conf database connection mysql+pymysql://glance:$GLANCE_DBPASS@$MYSQLHOST/glance

crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri http://$KEYSTONE_HOST:5000
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_url http://$KEYSTONE_HOST:35357
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_plugin password
crudini --set /etc/glance/glance-registry.conf keystone_authtoken project_domain_id default 
crudini --set /etc/glance/glance-registry.conf keystone_authtoken user_domain_id default
crudini --set /etc/glance/glance-registry.conf keystone_authtoken project_name service
crudini --set /etc/glance/glance-registry.conf keystone_authtoken username glance
crudini --set /etc/glance/glance-registry.conf keystone_authtoken password $GLANCE_PASS

crudini --set /etc/glance/glance-registry.conf paste_deploy flavor keystone

crudini --set /etc/glance/glance-registry.conf DEFAULT notification_driver noop
crudini --set /etc/glance/glance-registry.conf DEFAULT verbose True

diff /etc/glance/glance-api.conf /etc/glance/glance-api.conf.bak
diff /etc/glance/glance-registry.conf  /etc/glance/glance-registry.conf.bak

sleep 5

su -s /bin/sh -c "glance-manage db_sync" glance
service glance-registry restart
service glance-api restart
rm -f /var/lib/glance/glance.sqlite


## Set up novaC
echo "CREATE DATABASE nova;
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' \
  IDENTIFIED BY '$NOVA_DBPASS';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' \
  IDENTIFIED BY '$NOVA_DBPASS';
FLUSH PRIVILEGES;" | mysql --user=root --password=$MYSQL_ROOT_PASSWORD -h $MYSQLHOST -P 3306


openstack user create --domain default --password $NOVA_PASS nova
openstack role add --project service --user nova admin
openstack service create --name nova \
  --description "OpenStack Compute" compute
openstack endpoint create --region $REGION1 \
  compute public http://$NOVA_HOST:8774/v2/%\(tenant_id\)s
openstack endpoint create --region $REGION1 \
  compute internal http://$NOVA_HOST:8774/v2/%\(tenant_id\)s
openstack endpoint create --region $REGION1 \
  compute admin http://$NOVA_HOST:8774/v2/%\(tenant_id\)s  

apt-get install -y nova-api nova-cert nova-conductor \
  nova-consoleauth nova-novncproxy nova-scheduler \
  python-novaclient


cp /etc/nova/nova.conf /etc/nova/nova.conf.bak
crudini --set /etc/nova/nova.conf database connection mysql+pymysql://nova:$NOVA_DBPASS@$MYSQLHOST/nova

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

crudini --set /etc/nova/nova.conf DEFAULT my_ip $NOVA_HOST
crudini --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API
crudini --set /etc/nova/nova.conf DEFAULT security_group_api neutron
crudini --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.NeutronLinuxBridgeInterfaceDriver
crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

crudini --set /etc/nova/nova.conf vnc vncserver_listen $NOVA_HOST
crudini --set /etc/nova/nova.conf vnc vncserver_proxyclient_address $NOVA_HOST

crudini --set /etc/nova/nova.conf glance host $GLANCE_HOST

crudini --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

crudini --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata

crudini --set /etc/nova/nova.conf DEFAULT verbose True

# NETRON serup
crudini --set /etc/nova/nova.conf neutron url http://$NEUTRON_HOST:9696
crudini --set /etc/nova/nova.conf neutron auth_url http://$KEYSTONE_HOST:35357
crudini --set /etc/nova/nova.conf neutron auth_plugin password
crudini --set /etc/nova/nova.conf neutron project_domain_id default
crudini --set /etc/nova/nova.conf neutron user_domain_id default
crudini --set /etc/nova/nova.conf neutron region_name $REGION1
crudini --set /etc/nova/nova.conf neutron project_name service
crudini --set /etc/nova/nova.conf neutron username neutron
crudini --set /etc/nova/nova.conf neutron password $NEUTRON_PASS

service_metadata_proxy = True
metadata_proxy_shared_secret = METADATA_SECRET

diff /etc/nova/nova.conf /etc/nova/nova.conf.bak

sleep 5

su -s /bin/sh -c "nova-manage db sync" nova

service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart

rm -f /var/lib/nova/nova.sqlite



## set up neutron

echo "CREATE DATABASE neutron;
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

cp /etc/sysctl.conf /etc/sysctl.conf.bak 
cat <<EOF >> /etc/sysctl.conf
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
EOF
sysctl -p

apt-get install -y neutron-server \
  neutron-plugin-ml2 \
  neutron-plugin-linuxbridge-agent \
  neutron-dhcp-agent \
  neutron-metadata-agent \
  python-neutronclient

cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bak
crudini --set /etc/neutron/neutron.conf database connection mysql+pymysql://neutron:$NEUTRON_DBPASS@$MYSQLHOST/neutron
crudini --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
crudini --set /etc/neutron/neutron.conf DEFAULT service_plugins ""
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

crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True
crudini --set /etc/neutron/neutron.conf DEFAULT nova_url http://$NOVA_HOST:8774/v2

crudini --set /etc/neutron/neutron.conf nova auth_url http://$KEYSTONE_HOST:35357
crudini --set /etc/neutron/neutron.conf nova auth_plugin password
crudini --set /etc/neutron/neutron.conf nova project_domain_id default
crudini --set /etc/neutron/neutron.conf nova user_domain_id default
crudini --set /etc/neutron/neutron.conf nova region_name $REGION1
crudini --set /etc/neutron/neutron.conf nova project_name service
crudini --set /etc/neutron/neutron.conf nova username nova
crudini --set /etc/neutron/neutron.conf nova password $NOVA_PASS

crudini --set /etc/neutron/neutron.conf DEFAULT verbose True

diff /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bak

sleep 5

cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.bak
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types ""
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers linuxbridge
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks public

diff /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.bak

sleep 5

cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.bak
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings public:$NET_PUBLIC_INTERFACE_NAME
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan False
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini agent prevent_arp_spoofing True
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group True
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_ipset True
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

diff /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.bak

sleep 5

cp /etc/neutron/dhcp_agent.ini  /etc/neutron/dhcp_agent.ini.bak
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.BridgeInterfaceDriver
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata True
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT verbose True

diff /etc/neutron/dhcp_agent.ini  /etc/neutron/dhcp_agent.ini.bak

sleep 5

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

crudini --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip $NEUTRON_HOST
crudini --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret $METADATA_SECRET
crudini --set /etc/neutron/metadata_agent.ini DEFAULT verbose True

diff /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.bak


sleep 5

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron


service nova-api restart
service neutron-server restart
service neutron-plugin-linuxbridge-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart

# option 2
#service neutron-l3-agent restart


apt-get install -y openstack-dashboard
## TODO
# CONF /etc/openstack-dashboard/local_settings.py 
# service apache2 reload

echo "Keystone is available at $KEYSTONE_HOST:5000/v3"
echo "Users admin and demo were created"
echo "Password for admin: $ADMIN_PASS"
echo "Password for demo: $DEMO_PASS"

