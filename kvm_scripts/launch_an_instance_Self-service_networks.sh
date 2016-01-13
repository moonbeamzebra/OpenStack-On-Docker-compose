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

neutron net-create public \
--shared \
--provider:physical_network public \
--provider:network_type flat



neutron subnet-create public 10.199.5.0/24 \
--name public \
--allocation-pool start=10.199.5.80,end=10.199.5.89 \
--dns-nameserver 8.8.8.8 \
--gateway 10.199.5.1

neutron net-update public --router:external

source ~/demo-openrc.sh

neutron net-create private

neutron subnet-create private 172.16.1.0/24 --name private --gateway 172.16.1.1

neutron router-create router

neutron router-interface-add router private

neutron router-gateway-set router public

ssh-keygen -q -N ""
nova keypair-add --pub-key ~/.ssh/id_rsa.pub mykey

nova secgroup-create ALL "ALL ingress"
nova secgroup-add-rule ALL icmp -1 -1 0.0.0.0/0
nova secgroup-add-rule ALL tcp 1 65535 0.0.0.0/0
nova secgroup-add-rule ALL udp 1 65535 0.0.0.0/0


nova keypair-list
nova flavor-list
nova image-list


# PUBLIC INSTANCE
#nova boot \
#--flavor m1.tiny \
#--image cirros \
#--nic net-id=$(neutron net-show -f value -F id public) \
#--security-group ALL \
#--key-name mykey \
#public-instance


# PRIVATE INSTANCE
nova boot \
--flavor m1.tiny \
--image cirros \
--nic net-id=$(neutron net-show -f value -F id private) \
--security-group ALL \
--key-name mykey \
--user-data user_data_ubuntu.txt \
c1

neutron floatingip-create public

#nova floating-ip-associate private-instance {FLOATING_IP}

nova list

# PRIVATE INSTANCE (Ubuntu)
nova boot \
--flavor m1.small \
--image trusty-server \
--nic net-id=$(neutron net-show -f value -F id private) \
--security-group ALL \
--key-name mykey \
--user-data user_data_ubuntu.txt \
u1

neutron floatingip-create public

#nova floating-ip-associate private-instance-u {FLOATING_IP}

nova list

