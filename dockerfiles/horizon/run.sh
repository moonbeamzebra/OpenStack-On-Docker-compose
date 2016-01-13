#! /bin/bash +ex
memcached -u memcache &
/usr/sbin/apache2ctl -D FOREGROUND

