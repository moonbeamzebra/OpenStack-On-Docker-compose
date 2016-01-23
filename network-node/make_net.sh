BC_CONTAINER_NAME=$1
BC_CONTAINER_IP=$2
BC_INTERFACE_NAME=$3
BC_GATEWAY=$4
BC_MASK_LEADING_BITS=$5
BC_BRIDGE=$6
BC_VLAN=$7

BC_INT_INTERFACE_NAME=$BC_INTERFACE_NAME-int
BC_EXT_INTERFACE_NAME=$BC_INTERFACE_NAME-ext


sudo ip link add $BC_INT_INTERFACE_NAME type veth peer name $BC_EXT_INTERFACE_NAME

if [ -z "$BC_VLAN" ]; then
    sudo ovs-vsctl add-port $BC_BRIDGE $BC_EXT_INTERFACE_NAME
else
    sudo ovs-vsctl add-port $BC_BRIDGE $BC_EXT_INTERFACE_NAME tag=$BC_VLAN
fi

sudo ip link set netns $(docker inspect --format '{{ .State.Pid }}' $BC_CONTAINER_NAME)  $BC_INT_INTERFACE_NAME

sudo nsenter -t $(docker inspect --format '{{ .State.Pid }}' $BC_CONTAINER_NAME) -n ip link set $BC_INT_INTERFACE_NAME up
sudo ip link set $BC_EXT_INTERFACE_NAME up

sudo nsenter -t $(docker inspect --format '{{ .State.Pid }}' $BC_CONTAINER_NAME) -n ip addr add $BC_CONTAINER_IP/$BC_MASK_LEADING_BITS dev $BC_INT_INTERFACE_NAME
sudo nsenter -t $(docker inspect --format '{{ .State.Pid }}' $BC_CONTAINER_NAME) -n ip route add default via $BC_GATEWAY dev $BC_INT_INTERFACE_NAME





