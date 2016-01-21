source ~/demo-openrc.sh

NET_ID=$(neutron net-show -f value -F id private)

heat stack-create -f test-stack.yml \
-P "ImageID=cirros;NetID=$NET_ID" testStack
