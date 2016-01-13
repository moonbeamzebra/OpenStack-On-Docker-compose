source admin-openrc.sh

wget -P /tmp/images http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img

glance image-create \
--name "cirros" \
--file /tmp/images/cirros-0.3.4-x86_64-disk.img \
--disk-format qcow2 \
--container-format bare \
--visibility public \
--progress

glance image-list

source admin-openrc.sh

neutron net-create public \
--shared \
--provider:physical_network public \
--provider:network_type flat


neutron subnet-create public 10.199.5.0/24 \
--name public \
--allocation-pool start=10.199.5.160,end=10.199.5.169 \
--disable-dhcp \
--gateway 10.199.5.1


source demo-openrc.sh

ssh-keygen -q -N ""
nova keypair-add --pub-key .ssh/id_rsa.pub mykey

nova secgroup-create ALL "ALL ingress"
nova secgroup-add-rule ALL icmp -1 -1 0.0.0.0/0
nova secgroup-add-rule ALL tcp 1 65535 0.0.0.0/0
nova secgroup-add-rule ALL udp 1 65535 0.0.0.0/0


nova keypair-list
nova flavor-list
nova image-list

nova boot \
--flavor m1.tiny \
--image cirros \
--nic net-id=$(neutron net-show -f value -F id public),v4-fixed-ip=10.199.5.165 \
--security-group ALL \
--key-name mykey \
public-instance



source demo-openrc.sh

neutron net-create demo-net

neutron subnet-create \
demo-net 192.168.1.0/24 \
--name demo-subnet \
--gateway 192.168.1.1

neutron router-create demo-router

neutron router-interface-add demo-router demo-subnet

neutron router-gateway-set demo-router ext-net

nova keypair-list
nova flavor-list
nova image-list
neutron net-list
nova secgroup-list

nova boot \
--flavor m1.tiny \
--image f0c06a1f-f0bd-46ef-9845-5ff1723e7f03 \
--nic net-id=f71937aa-fea1-465f-8ace-d4f03b0ef0cc \
--security-group ALL \
--key-name osu_at_api01 \
c1