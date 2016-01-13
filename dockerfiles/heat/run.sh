#! /bin/bash +ex

service heat-api restart
service heat-api-cfn restart
service heat-engine restart

sleep 3

tail -f /var/log/heat/*.log
