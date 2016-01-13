#! /bin/bash

crudini --set /etc/ceilometer/ceilometer.conf database connection mongodb://ceilometer:lab1@$MONGO_HOST:27017/ceilometer
crudini --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_host $RABBIT_HOST
crudini --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_password $RABBITMQ_DEFAULT_PASS
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_uri http://$KEYSTONE_HOST:5000/v2.0
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken identity_uri http://$KEYSTONE_HOST:35357
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken admin_password $CEIL_PASS
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_auth_url http://$KEYSTONE_HOST:5000/v2.0
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_password $CEIL_PASS
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_region_name $REGION1
crudini --set /etc/ceilometer/ceilometer.conf publisher telemetry_secret $CEIL_PASS



