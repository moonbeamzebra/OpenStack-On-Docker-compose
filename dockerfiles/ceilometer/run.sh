#! /bin/bash +ex


./wait_for_rabbitmq.sh

./wait_for_mongo.sh

source /admin-openrc.sh

./wait_for_ks_admin_ep.sh
./wait_for_nova_api.sh
./wait_for_neutron_api.sh
./wait_for_glance_api.sh

sleep 2

service ceilometer-agent-central restart
service ceilometer-agent-notification restart
service ceilometer-api restart
service ceilometer-collector restart
service ceilometer-alarm-evaluator restart
service ceilometer-alarm-notifier restart

sleep 3

tail -f /var/log/ceilometer/*.log
