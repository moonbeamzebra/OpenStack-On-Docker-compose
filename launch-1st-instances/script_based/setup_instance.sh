
source ~/demo-openrc.sh



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

