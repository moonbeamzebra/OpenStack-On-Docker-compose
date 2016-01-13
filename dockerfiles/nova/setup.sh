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


source /admin-openrc.sh


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
crudini --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
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
crudini --set /etc/nova/nova.conf neutron service_metadata_proxy True
crudini --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret $METADATA_SECRET

diff /etc/nova/nova.conf /etc/nova/nova.conf.bak

sleep 5

su -s /bin/sh -c "nova-manage db sync" nova 2>&1 > /var/log/nova/nova-manage.out 

service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart

rm -f /var/lib/nova/nova.sqlite

touch /setup.done
