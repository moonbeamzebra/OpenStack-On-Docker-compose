source ~/demo-openrc.sh

PUB_NET_ID=$(neutron net-show -f value -F id public)

heat stack-create -f test-stack.yml \
-P "image_id=cirros;flavor_id=m1.tiny;public_network=$PUB_NET_ID" testStack
