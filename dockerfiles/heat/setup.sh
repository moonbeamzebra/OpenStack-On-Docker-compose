#! /bin/bash
echo "CREATE DATABASE heat;
GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'localhost' IDENTIFIED BY '$HEAT_DBPASS';
GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'%' IDENTIFIED BY '$HEAT_DBPASS';
FLUSH PRIVILEGES;" | mysql --user=root --password=$MYSQL_ROOT_PASSWORD -h $MYSQLHOST -P 3306


crudini --set /etc/heat/heat.conf database connection mysql://heat:$HEAT_DBPASS@$MYSQLHOST/heat
crudini --set /etc/heat/heat.conf oslo_messaging_rabbit rabbit_host $RABBIT_HOST
crudini --set /etc/heat/heat.conf oslo_messaging_rabbit rabbit_userid $RABBITMQ_DEFAULT_USER
crudini --set /etc/heat/heat.conf oslo_messaging_rabbit rabbit_password $RABBITMQ_DEFAULT_PASS
crudini --set /etc/heat/heat.conf keystone_authtoken auth_uri http://$KEYSTONE_HOST:5000/v2.0
crudini --set /etc/heat/heat.conf keystone_authtoken identity_uri http://$KEYSTONE_HOST:35357
crudini --set /etc/heat/heat.conf keystone_authtoken admin_password $HEAT_PASS
crudini --set /etc/heat/heat.conf ec2authtoken auth_uri http://$KEYSTONE_HOST:5000/v2.0
crudini --set /etc/heat/heat.conf DEFAULT heat_metadata_server_url http://$HEAT_HOST:8000
crudini --set /etc/heat/heat.conf DEFAULT heat_waitcondition_server_url http://$HEAT_HOST:8000/v1/waitcondition
crudini --set /etc/heat/heat.conf DEFAULT stack_domain_admin_password $HEAT_PASS




sleep 5

heat-keystone-setup-domain --stack-user-domain-name heat_user_domain --stack-domain-admin heat_domain_admin --stack-domain-admin-password $HEAT_PASS

sleep 5

su -s /bin/sh -c "heat-manage db_sync" heat

rm -f /var/lib/heat/heat.sqlite


