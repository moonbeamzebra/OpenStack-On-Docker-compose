#! /bin/bash +ex
service ssh restart
tail -F /var/log/bootstrap.log
