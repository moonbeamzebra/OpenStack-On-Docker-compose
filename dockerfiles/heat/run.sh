#! /bin/bash +ex


./wait_for_rabbitmq.sh


service heat-api restart
service heat-api-cfn restart
service heat-engine restart

tail -f /var/log/heat/*.log
