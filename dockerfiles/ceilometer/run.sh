#! /bin/bash +ex

service ceilometer-agent-central restart
service ceilometer-agent-notification restart
service ceilometer-api restart
service ceilometer-collector restart
service ceilometer-alarm-evaluator restart
service ceilometer-alarm-notifier restart

sleep 3

tail -f /var/log/ceilometer/*.log
