#! /bin/bash +ex
memcached -u memcache &
/usr/sbin/apache2ctl -D FOREGROUND
touch /var/log/apache2/access.log
tail -F /var/log/apache2/access.log

