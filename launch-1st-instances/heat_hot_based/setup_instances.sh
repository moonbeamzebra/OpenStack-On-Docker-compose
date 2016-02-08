source ~/demo-openrc.sh

PRIVATE_NET_ID=$(neutron net-show -f value -F id demo_hot_net_private)
PUB_NET_ID=$(neutron net-show -f value -F id public)


heat stack-create -f instance.yaml \
-P "instance_name=hot_c1;image_id=cirros;flavor_id=m1.tiny;secgroup_id=demo_hot_ping_ssh_security_group;private_network=$PRIVATE_NET_ID;public_network=$PUB_NET_ID" hot_c1
heat stack-create -f instance.yaml \
-P "instance_name=hot_u1;image_id=trusty-server;flavor_id=m1.small;secgroup_id=demo_hot_ping_ssh_security_group;private_network=$PRIVATE_NET_ID;public_network=$PUB_NET_ID" hot_u1
