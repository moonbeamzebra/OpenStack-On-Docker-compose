#! /bin/bash +ex
memcached -u memcache & 
#service memcache restart
service apache2 restart
touch /var/log/apache2/access.log
tail -F /var/log/apache2/access.log
#memcached -u memcache & 
#/usr/sbin/apache2ctl -D FOREGROUND

