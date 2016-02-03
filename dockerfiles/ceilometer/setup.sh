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

crudini --set /etc/ceilometer/ceilometer.conf database connection mongodb://ceilometer:$CEIL_DBPASS@$MONGO_HOST:27017/ceilometer

crudini --set /etc/ceilometer/ceilometer.conf DEFAULT rpc_backend rabbit
crudini --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_host $RABBIT_HOST
crudini --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_userid $RABBITMQ_DEFAULT_USER
crudini --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_password $RABBITMQ_DEFAULT_PASS

crudini --set /etc/ceilometer/ceilometer.conf DEFAULT auth_strategy keystone
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_uri http://$KEYSTONE_HOST:5000
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_url http://$KEYSTONE_HOST:35357
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_plugin password
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken project_domain_id default
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken user_domain_id default
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken project_name service
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken username ceilometer
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken password $CEIL_PASS

crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_auth_url http://$KEYSTONE_HOST:5000/v2.0
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_username ceilometer
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_tenant_name service
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_password $CEIL_PASS
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_endpoint_type internalURL
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_region_name $REGION1

crudini --set /etc/ceilometer/ceilometer.conf DEFAULT verbose True

./wait_for_mongo.sh noauth
sleep 1

echo "$CEIL_DBPASS"
mongo --host $MONGO_HOST --eval '
  db = db.getSiblingDB("ceilometer");
  db.addUser({user: "ceilometer",
  pwd: "ceildb1",
  roles: [ "readWrite", "dbAdmin" ]})'

touch /setup.done
