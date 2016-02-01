#! /bin/bash



if [ -f /setup.done ];
then
   echo "Setup done" > /tmp/done
   exit 0
fi

cat <<EOF > /admin-openrc.sh
export OS_PROJECT_DOMAIN_ID=default
export OS_USER_DOMAIN_ID=default
export OS_PROJECT_NAME=admin
export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_AUTH_URL=http://$KEYSTONE_HOST:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

cat <<EOF > /demo-openrc.sh
export OS_PROJECT_DOMAIN_ID=default
export OS_USER_DOMAIN_ID=default
export OS_PROJECT_NAME=demo
export OS_TENANT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=$DEMO_PASS
export OS_AUTH_URL=http://$KEYSTONE_HOST:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

cp /etc/mongodb.conf /etc/mongodb.conf.bak
sed -i "s/bind_ip/#bind_ip/g" /etc/mongodb.conf
sed -i "s/smallfiles/#smallfiles/g" /etc/mongodb.conf
echo "bind_ip = 0.0.0.0" >> /etc/mongodb.conf
echo "smallfiles = true" >> /etc/mongodb.conf


sleep 5
service mongodb stop
sleep 5
rm -f /var/lib/mongodb/journal/prealloc.*
#service mongodb start
#service mongodb restart

touch /setup.done
