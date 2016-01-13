#! /bin/bash


## Set up keystone
echo "CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$KEYSTONE_DBPASS';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$KEYSTONE_DBPASS';
FLUSH PRIVILEGES;" | mysql --user=root --password=$MYSQL_ROOT_PASSWORD -h $MYSQLHOST -P 3306

su -s /bin/sh -c "keystone-manage db_sync" keystone

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


