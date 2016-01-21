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

echo "CREATE DATABASE heat;
GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'localhost' IDENTIFIED BY '$HEAT_DBPASS';
GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'%' IDENTIFIED BY '$HEAT_DBPASS';
FLUSH PRIVILEGES;" | mysql --user=root --password=$MYSQL_ROOT_PASSWORD -h $MYSQLHOST -P 3306



./wait_for_ks_admin_ep.sh



openstack user create --domain default --password $HEAT_PASS heat
openstack role add --project service --user heat admin
openstack service create --name heat \
 --description "Orchestration" orchestration
openstack service create --name heat-cfn \
   --description "Orchestration"  cloudformation
openstack endpoint create --region $REGION1 \
  orchestration public http://$HEAT_HOST:8004/v1/%\(tenant_id\)s
openstack endpoint create --region $REGION1 \
  orchestration internal http://$HEAT_HOST:8004/v1/%\(tenant_id\)s
openstack endpoint create --region $REGION1 \
  orchestration admin http://$HEAT_HOST:8004/v1/%\(tenant_id\)s
openstack endpoint create --region $REGION1 \
  cloudformation public http://$HEAT_HOST:8000/v1
openstack endpoint create --region $REGION1 \
  cloudformation internal http://$HEAT_HOST:8000/v1
openstack endpoint create --region $REGION1 \
  cloudformation admin http://$HEAT_HOST:8000/v1
openstack domain create --description "Stack projects and users" heat
openstack user create --domain heat --password $HEAT_DOMAIN_PASS heat_domain_admin
openstack role add --domain heat --user heat_domain_admin admin
openstack role create heat_stack_owner
openstack role add --project demo --user demo heat_stack_owner
openstack role create heat_stack_user



cp /etc/heat/heat.conf /etc/heat/heat.conf.bak
crudini --set /etc/heat/heat.conf database connection mysql+pymysql://heat:$HEAT_DBPASS@$MYSQLHOST/heat

crudini --set /etc/heat/heat.conf DEFAULT rpc_backend rabbit
crudini --set /etc/heat/heat.conf  oslo_messaging_rabbit rabbit_host $RABBIT_HOST
crudini --set /etc/heat/heat.conf oslo_messaging_rabbit rabbit_userid $RABBITMQ_DEFAULT_USER
crudini --set /etc/heat/heat.conf oslo_messaging_rabbit rabbit_password $RABBITMQ_DEFAULT_PASS

crudini --set /etc/heat/heat.conf keystone_authtoken auth_uri http://$KEYSTONE_HOST:5000
crudini --set /etc/heat/heat.conf keystone_authtoken auth_url http://$KEYSTONE_HOST:35357
crudini --set /etc/heat/heat.conf keystone_authtoken auth_plugin password
crudini --set /etc/heat/heat.conf keystone_authtoken project_domain_id default
crudini --set /etc/heat/heat.conf keystone_authtoken user_domain_id default
crudini --set /etc/heat/heat.conf keystone_authtoken project_name service
crudini --set /etc/heat/heat.conf keystone_authtoken username heat
crudini --set /etc/heat/heat.conf keystone_authtoken password $HEAT_PASS

crudini --set /etc/heat/heat.conf trustee auth_uri http://$KEYSTONE_HOST:5000
crudini --set /etc/heat/heat.conf trustee auth_url http://$KEYSTONE_HOST:35357
crudini --set /etc/heat/heat.conf trustee auth_plugin password
crudini --set /etc/heat/heat.conf trustee project_domain_id default
crudini --set /etc/heat/heat.conf trustee user_domain_id default
crudini --set /etc/heat/heat.conf trustee project_name service
crudini --set /etc/heat/heat.conf trustee username heat
crudini --set /etc/heat/heat.conf trustee password $HEAT_PASS

crudini --set /etc/heat/heat.conf clients_keystone auth_uri http://$KEYSTONE_HOST:5000

crudini --set /etc/heat/heat.conf ec2authtoken auth_uri http://$KEYSTONE_HOST:5000

crudini --set /etc/heat/heat.conf DEFAULT heat_metadata_server_url http://$HEAT_HOST:8000
crudini --set /etc/heat/heat.conf DEFAULT heat_waitcondition_server_url http://$HEAT_HOST:8000/v1/waitcondition

crudini --set /etc/heat/heat.conf DEFAULT stack_domain_admin heat_domain_admin
crudini --set /etc/heat/heat.conf DEFAULT stack_domain_admin_password $HEAT_DOMAIN_PASS
crudini --set /etc/heat/heat.conf DEFAULT stack_user_domain_name heat

crudini --set /etc/heat/heat.conf DEFAULT verbose True

diff /etc/heat/heat.conf  /etc/heat/heat.conf.bak

sleep 5

su -s /bin/sh -c "heat-manage db_sync" heat 2>&1 > /var/log/heat/heat-manage.out

service heat-api restart
service heat-api-cfn restart
service heat-engine restart

rm -f /var/lib/heat/heat.sqlite

touch /setup.done
