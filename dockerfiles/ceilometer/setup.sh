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

./wait_for_ks_admin_ep.sh

openstack user create --domain default --password $CEIL_PASS ceilometer
openstack role add --project service --user ceilometer admin
openstack service create --name ceilometer \
  --description "Telemetry" metering
openstack endpoint create --region $REGION1 \
    metering public http://$CEIL_HOST:8777
openstack endpoint create --region $REGION1 \
    metering internal http://$CEIL_HOST:8777
openstack endpoint create --region $REGION1 \
      metering admin http://$CEIL_HOST:8777

cp /etc/ceilometer/ceilometer.conf /etc/ceilometer/ceilometer.conf.bak
crudini --set /etc/ceilometer/ceilometer.conf database connection mongodb://ceilometer:$CEIL_DBPASS@$MONGO_HOST:27017/ceilometer

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

crudini --set /etc/ceilometer/ceilometer.conf service_credentials auth_type password
crudini --set /etc/ceilometer/ceilometer.conf service_credentials auth_url http://$KEYSTONE_HOST:5000/v3
crudini --set /etc/ceilometer/ceilometer.conf service_credentials project_domain_name default
crudini --set /etc/ceilometer/ceilometer.conf service_credentials user_domain_name default
crudini --set /etc/ceilometer/ceilometer.conf service_credentials project_name service
crudini --set /etc/ceilometer/ceilometer.conf service_credentials username ceilometer
crudini --set /etc/ceilometer/ceilometer.conf service_credentials password $CEIL_PASS
crudini --set /etc/ceilometer/ceilometer.conf service_credentials interface internalURL
crudini --set /etc/ceilometer/ceilometer.conf service_credentials region_name $REGION1

crudini --set /etc/ceilometer/ceilometer.conf DEFAULT verbose True

diff /etc/ceilometer/ceilometer.conf  /etc/ceilometer/ceilometer.conf.bak

./wait_for_mongo.sh noauth
sleep 1

echo "$CEIL_DBPASS"
mongo --host $MONGO_HOST --eval '
  db = db.getSiblingDB("ceilometer");
  db.addUser({user: "ceilometer",
  pwd: "ceildb1",
  roles: [ "readWrite", "dbAdmin" ]})'

#Alarming service
#TODO : make another container for it

echo "DROP DATABASE IF EXISTS aodh;
CREATE DATABASE aodh;
GRANT ALL PRIVILEGES ON aodh.* TO 'aodh'@'localhost' IDENTIFIED BY '$AODH_DBPASS';
GRANT ALL PRIVILEGES ON aodh.* TO 'aodh'@'%' IDENTIFIED BY '$AODH_DBPASS';
FLUSH PRIVILEGES;" | mysql --user=root --password=$MYSQL_ROOT_PASSWORD -h $MYSQLHOST -P 3306

openstack user create --domain default --password $AODH_PASS aodh
openstack role add --project service --user aodh admin
openstack service create --name aodh \
  --description "Telemetry alarming" alarming
openstack endpoint create --region $REGION1 \
  alarming public http://$AODH_HOST:8042
openstack endpoint create --region $REGION1 \
  alarming internal http://$AODH_HOST:8042
openstack endpoint create --region $REGION1 \
    alarming admin http://$AODH_HOST:8042

cp /etc/aodh/aodh.conf /etc/aodh/aodh.conf.bak
crudini --set /etc/aodh/aodh.conf database connection mysql+pymysql://aodh:$AODH_DBPASS@$MYSQLHOST/aodh
crudini --set /etc/aodh/aodh.conf DEFAULT rpc_backend rabbit

crudini --set /etc/aodh/aodh.conf oslo_messaging_rabbit rabbit_host $RABBIT_HOST
crudini --set /etc/aodh/aodh.conf oslo_messaging_rabbit rabbit_userid $RABBITMQ_DEFAULT_USER
crudini --set /etc/aodh/aodh.conf oslo_messaging_rabbit rabbit_password $RABBITMQ_DEFAULT_PASS

crudini --set /etc/aodh/aodh.conf DEFAULT auth_strategy keystone
crudini --set /etc/aodh/aodh.conf keystone_authtoken auth_uri http://$KEYSTONE_HOST:5000
crudini --set /etc/aodh/aodh.conf keystone_authtoken auth_url http://$KEYSTONE_HOST:35357
crudini --set /etc/aodh/aodh.conf keystone_authtoken memcached_servers $KEYSTONE_HOST:11211
crudini --set /etc/aodh/aodh.conf keystone_authtoken auth_type password
crudini --set /etc/aodh/aodh.conf keystone_authtoken project_domain_name default
crudini --set /etc/aodh/aodh.conf keystone_authtoken user_domain_name default
crudini --set /etc/aodh/aodh.conf keystone_authtoken project_name service
crudini --set /etc/aodh/aodh.conf keystone_authtoken username aodh
crudini --set /etc/aodh/aodh.conf keystone_authtoken password $AODH_PASS

crudini --set /etc/aodh/aodh.conf service_credentials auth_type password
crudini --set /etc/aodh/aodh.conf service_credentials auth_url http://$KEYSTONE_HOST:5000/v3
crudini --set /etc/aodh/aodh.conf service_credentials project_domain_name default
crudini --set /etc/aodh/aodh.conf service_credentials user_domain_name default
crudini --set /etc/aodh/aodh.conf service_credentials project_name service
crudini --set /etc/aodh/aodh.conf service_credentials username aodh
crudini --set /etc/aodh/aodh.conf service_credentials password $AODH_PASS
crudini --set /etc/aodh/aodh.conf service_credentials interface internalURL
crudini --set /etc/aodh/aodh.conf service_credentials region_name $REGION1

diff /etc/aodh/aodh.conf /etc/aodh/aodh.conf.bak

cp /etc/aodh/api_paste.ini /etc/aodh/api_paste.ini.bak
crudini --set /etc/aodh/api_paste.ini filter:authtoken oslo_config_project aodh
diff /etc/aodh/api_paste.ini /etc/aodh/api_paste.ini.bak

touch /setup.done
