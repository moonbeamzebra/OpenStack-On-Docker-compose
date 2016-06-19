#! /bin/bash

if [ -f /setup.done ];
then
   echo "Setup done" > /tmp/done
   exit 0
fi

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

echo "CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$GLANCE_DBPASS';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$GLANCE_DBPASS';
FLUSH PRIVILEGES;" | mysql --user=root --password=$MYSQL_ROOT_PASSWORD -h $MYSQLHOST -P 3306




./wait_for_ks_admin_ep.sh




openstack user create --domain default --password $GLANCE_PASS glance
openstack role add --project service --user glance admin
openstack service create --name glance \
  --description "OpenStack Image" image
openstack endpoint create --region $REGION1 \
  image public http://$GLANCE_HOST:9292
openstack endpoint create --region $REGION1 \
  image internal http://$GLANCE_HOST:9292
openstack endpoint create --region $REGION1 \
  image admin http://$GLANCE_HOST:9292


cp /etc/glance/glance-api.conf /etc/glance/glance-api.conf.bak
crudini --set /etc/glance/glance-api.conf database connection mysql+pymysql://glance:$GLANCE_DBPASS@$MYSQLHOST/glance

crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_uri http://$KEYSTONE_HOST:5000
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_url http://$KEYSTONE_HOST:35357
crudini --set /etc/glance/glance-api.conf keystone_authtoken memcached_servers $KEYSTONE_HOST:11211
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_type password
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_domain_name default
crudini --set /etc/glance/glance-api.conf keystone_authtoken user_domain_name default
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_name service
crudini --set /etc/glance/glance-api.conf keystone_authtoken username glance
crudini --set /etc/glance/glance-api.conf keystone_authtoken password $GLANCE_PASS

crudini --set /etc/glance/glance-api.conf paste_deploy flavor keystone

crudini --set /etc/glance/glance-api.conf glance_store stores file,http
crudini --set /etc/glance/glance-api.conf glance_store default_store file
crudini --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images/

crudini --set /etc/glance/glance-api.conf DEFAULT rpc_backend rabbit
crudini --set /etc/glance/glance-api.conf DEFAULT verbose True

crudini --set /etc/glance/glance-api.conf oslo_messaging_notifications driver messagingv2

crudini --set /etc/glance/glance-api.conf oslo_messaging_rabbit rabbit_host $RABBIT_HOST
crudini --set /etc/glance/glance-api.conf oslo_messaging_rabbit rabbit_userid $RABBITMQ_DEFAULT_USER
crudini --set /etc/glance/glance-api.conf oslo_messaging_rabbit rabbit_password $RABBITMQ_DEFAULT_PASS

cp /etc/glance/glance-registry.conf  /etc/glance/glance-registry.conf.bak

crudini --set /etc/glance/glance-registry.conf database connection mysql+pymysql://glance:$GLANCE_DBPASS@$MYSQLHOST/glance

crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri http://$KEYSTONE_HOST:5000
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_url http://$KEYSTONE_HOST:35357
crudini --set /etc/glance/glance-registry.conf keystone_authtoken memcached_servers $KEYSTONE_HOST:11211
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_type password
crudini --set /etc/glance/glance-registry.conf keystone_authtoken project_domain_name default
crudini --set /etc/glance/glance-registry.conf keystone_authtoken user_domain_name default
crudini --set /etc/glance/glance-registry.conf keystone_authtoken project_name service
crudini --set /etc/glance/glance-registry.conf keystone_authtoken username glance
crudini --set /etc/glance/glance-registry.conf keystone_authtoken password $GLANCE_PASS

crudini --set /etc/glance/glance-registry.conf paste_deploy flavor keystone

crudini --set /etc/glance/glance-registry.conf DEFAULT rpc_backend rabbit
crudini --set /etc/glance/glance-registry.conf DEFAULT verbose True

crudini --set /etc/glance/glance-registry.conf oslo_messaging_notifications driver messagingv2

crudini --set /etc/glance/glance-registry.conf oslo_messaging_rabbit rabbit_host $RABBIT_HOST
crudini --set /etc/glance/glance-registry.conf oslo_messaging_rabbit rabbit_userid $RABBITMQ_DEFAULT_USER
crudini --set /etc/glance/glance-registry.conf oslo_messaging_rabbit rabbit_password $RABBITMQ_DEFAULT_PASS

diff /etc/glance/glance-api.conf /etc/glance/glance-api.conf.bak
diff /etc/glance/glance-registry.conf  /etc/glance/glance-registry.conf.bak

sleep 5

su -s /bin/sh -c "glance-manage db_sync" glance 2>&1 > /var/log/glance/glance-manage.out
service glance-registry restart
service glance-api restart
rm -f /var/lib/glance/glance.sqlite

touch /setup.done
