source ~/admin-openrc.sh

wget -P /tmp/images http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img

glance image-create \
--name "cirros" \
--file /tmp/images/cirros-0.3.4-x86_64-disk.img \
--disk-format qcow2 \
--container-format bare \
--visibility public \
--progress

wget -P /tmp/images http://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img

glance image-create \
--name "trusty-server" \
--file /tmp/images/trusty-server-cloudimg-amd64-disk1.img \
--disk-format qcow2 \
--container-format bare \
--visibility public \
--progress

glance image-list

