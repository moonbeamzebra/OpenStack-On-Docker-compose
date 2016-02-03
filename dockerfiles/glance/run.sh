#! /bin/bash +ex

./wait_for_rabbitmq.sh

service glance-registry restart
service glance-api restart

tail -f /var/log/glance/*.log
