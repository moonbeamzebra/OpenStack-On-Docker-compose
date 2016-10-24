#! /bin/bash

if [ -f /setup.done ];
then
   echo "Setup done" > /tmp/done
   exit 0
fi

## Set up keystone
echo "DROP DATABASE IF EXISTS keystone;
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$KEYSTONE_DBPASS';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$KEYSTONE_DBPASS';
FLUSH PRIVILEGES;" | mysql --user=root --password=$MYSQL_ROOT_PASSWORD -h $MYSQLHOST -P 3306

cp /etc/keystone/keystone.conf /etc/keystone/keystone.conf.bak
crudini --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:$KEYSTONE_DBPASS@$MYSQLHOST/keystone
crudini --set /etc/keystone/keystone.conf token provider fernet
diff /etc/keystone/keystone.conf /etc/keystone/keystone.conf.bak

sleep 5

su -s /bin/sh -c "keystone-manage db_sync" keystone 2>&1 > /var/log/keystone/keystone-manage.out

keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

keystone-manage bootstrap --bootstrap-password $ADMIN_PASS \
  --bootstrap-admin-url http://$KEYSTONE_HOST:35357/v3/ \
  --bootstrap-internal-url http://$KEYSTONE_HOST:35357/v3/ \
  --bootstrap-public-url http://$KEYSTONE_HOST:5000/v3/ \
  --bootstrap-region-id $REGION1


echo "ServerName `hostname`" >> /etc/apache2/apache2.conf


service apache2 restart
rm -f /var/lib/keystone/keystone.db

sleep 5

export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://$KEYSTONE_HOST:35357/v3
export OS_IDENTITY_API_VERSION=3

openstack project create --domain default \
  --description "Service Project" service
openstack project create --domain default \
  --description "Demo Project" demo

openstack user create  --domain default --password $DEMO_PASS demo
openstack role create user

openstack role add --project demo --user demo user


cat <<EOF > /admin-openrc.sh
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
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
export OS_USERNAME=demo
export OS_PASSWORD=$DEMO_PASS
export OS_AUTH_URL=http://$KEYSTONE_HOST:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF


touch /setup.done
