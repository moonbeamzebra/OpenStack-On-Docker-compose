#! /bin/bash +ex
memcached -u memcache &
rm -f /var/run/apache2/apache2.pid
/usr/sbin/apache2ctl -D FOREGROUND
#touch /var/log/apache2/access.log
#tail -F /var/log/apache2/access.log

