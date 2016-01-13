source ~/admin-openrc.sh


neutron net-create public \
--shared \
--provider:physical_network external \
--provider:network_type flat



neutron subnet-create public 10.199.5.0/24 \
--name public \
--allocation-pool start=10.199.5.80,end=10.199.5.89 \
--dns-nameserver 8.8.8.8 \
--gateway 10.199.5.1

neutron net-update public --router:external 

source ~/demo-openrc.sh

neutron net-create private

neutron subnet-create private 172.16.1.0/24 \
--name private \
--dns-nameserver 8.8.8.8 \
--gateway 172.16.1.1

neutron router-create router

neutron router-interface-add router private

neutron router-gateway-set router public

