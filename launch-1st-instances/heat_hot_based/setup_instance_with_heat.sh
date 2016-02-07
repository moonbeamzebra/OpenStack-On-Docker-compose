source ~/demo-openrc.sh

PRIVATE_NET_ID=$(neutron net-show -f value -F id demo_hot_net_private)
PUB_NET_ID=$(neutron net-show -f value -F id public)


#heat stack-create -f instance-i1.yaml \
#-P "image_id=cirros;flavor_id=m1.tiny;private_network=$PRIVATE_NET_ID;public_network=$PUB_NET_ID" demo_instance-i1
heat stack-create -f instance-i1.yaml \
-P "image_id=trusty-server;flavor_id=m1.small;private_network=$PRIVATE_NET_ID;public_network=$PUB_NET_ID" demo_instance-i1
