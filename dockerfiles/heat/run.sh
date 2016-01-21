#! /bin/bash +ex

service heat-api restart
service heat-api-cfn restart
service heat-engine restart

tail -f /var/log/heat/*.log
