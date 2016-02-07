source ~/demo-openrc.sh

PUB_NET_ID=$(neutron net-show -f value -F id public)

heat stack-create -f private_net.yml \
-P "public_network=$PUB_NET_ID" demo_private_net
