#! /bin/bash +ex

service glance-registry restart
service glance-api restart

tail -f /var/log/glance/*.log
