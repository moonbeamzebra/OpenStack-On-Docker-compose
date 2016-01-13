#! /bin/bash

if [ -f /setup.done ];
then
   echo "Setup done" > /tmp/done
   exit 0
fi

## Set up keystone
echo "CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$KEYSTONE_DBPASS';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$KEYSTONE_DBPASS';
FLUSH PRIVILEGES;" | mysql --user=root --password=$MYSQL_ROOT_PASSWORD -h $MYSQLHOST -P 3306

echo "manual" > /etc/init/keystone.override

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

su -s /bin/sh -c "keystone-manage db_sync" keystone 2>&1 > /var/log/keystone/keystone-manage.out 

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


touch /setup.done
