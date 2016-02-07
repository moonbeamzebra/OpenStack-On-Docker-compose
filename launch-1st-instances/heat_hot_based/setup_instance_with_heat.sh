source ~/demo-openrc.sh

PRIVATE_NET_ID=$(neutron net-show -f value -F id demo_hot_net_private)

heat stack-create -f instance-i1.yaml \
-P "image_id=cirros;flavor_id=m1.tiny;private_network=$PRIVATE_NET_ID" demo_instance-i1
