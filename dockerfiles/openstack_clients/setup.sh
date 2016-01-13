#! /bin/bash

useradd -d /home/osu -m -s /bin/bash osu
echo osu:osu1 | chpasswd
adduser osu sudo

cat <<EOF > /home/osu/admin-openrc.sh
export OS_PROJECT_DOMAIN_ID=default
export OS_USER_DOMAIN_ID=default
export OS_PROJECT_NAME=admin
export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_AUTH_URL=http://$KEYSTONE_HOST:35357/v3
export OS_IMAGE_API_VERSION=2
EOF

cp /home/osu/admin-openrc.sh /
chown osu:osu /home/osu/admin-openrc.sh

cat <<EOF > /home/osu/demo-openrc.sh
export OS_PROJECT_DOMAIN_ID=default
export OS_USER_DOMAIN_ID=default
export OS_PROJECT_NAME=demo
export OS_TENANT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=$DEMO_PASS
export OS_AUTH_URL=http://$KEYSTONE_HOST:5000/v3
export OS_IMAGE_API_VERSION=2
EOF

cp /home/osu/demo-openrc.sh /
chown osu:osu /home/osu/demo-openrc.sh

cd /home/osu
git clone https://github.com/moonbeamzebra/OpenStack-On-Docker.git
chown -R osu: OpenStack-On-Docker
cd -
