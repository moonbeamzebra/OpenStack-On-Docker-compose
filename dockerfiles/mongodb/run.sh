#! /bin/bash +ex

service mongodb restart

tail -F /var/log/bootstrap.log
