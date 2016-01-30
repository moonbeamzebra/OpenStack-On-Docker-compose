
MY_INTERFACE_NAME=oscn

MY_INT_INTERFACE_NAME=$MY_INTERFACE_NAME
MY_EXT_INTERFACE_NAME=$MY_INTERFACE_NAME-ext

MY_CONTAINER_NAME=os-compute-node
MY_CONTAINER_ETH0_IP=192.168.2.246
MY_CONTAINER_ETH1_IP=192.168.2.247
MY_MASK_LEADING_BITS=24
MY_GATEWAY=192.168.2.1

sudo ip link add $MY_INT_INTERFACE_NAME-0 type veth peer name $MY_EXT_INTERFACE_NAME-0
sudo ip link add $MY_INT_INTERFACE_NAME-1 type veth peer name $MY_EXT_INTERFACE_NAME-1
sudo ip link add $MY_INT_INTERFACE_NAME-2 type veth peer name $MY_EXT_INTERFACE_NAME-2

sudo brctl addif br0 $MY_EXT_INTERFACE_NAME-0
sudo brctl addif br0 $MY_EXT_INTERFACE_NAME-1
sudo brctl addif br0 $MY_EXT_INTERFACE_NAME-2

sudo ip link set netns $(docker inspect --format '{{ .State.Pid }}' $MY_CONTAINER_NAME)  $MY_INT_INTERFACE_NAME-0
sudo ip link set netns $(docker inspect --format '{{ .State.Pid }}' $MY_CONTAINER_NAME)  $MY_INT_INTERFACE_NAME-1
sudo ip link set netns $(docker inspect --format '{{ .State.Pid }}' $MY_CONTAINER_NAME)  $MY_INT_INTERFACE_NAME-2

sudo nsenter -t $(docker inspect --format '{{ .State.Pid }}' $MY_CONTAINER_NAME) -n ip link set $MY_INT_INTERFACE_NAME-0 up
sudo nsenter -t $(docker inspect --format '{{ .State.Pid }}' $MY_CONTAINER_NAME) -n ip link set $MY_INT_INTERFACE_NAME-1 up
sudo nsenter -t $(docker inspect --format '{{ .State.Pid }}' $MY_CONTAINER_NAME) -n ip link set $MY_INT_INTERFACE_NAME-2 up
sudo ip link set $MY_EXT_INTERFACE_NAME-0 up
sudo ip link set $MY_EXT_INTERFACE_NAME-1 up
sudo ip link set $MY_EXT_INTERFACE_NAME-2 up

sudo nsenter -t $(docker inspect --format '{{ .State.Pid }}' $MY_CONTAINER_NAME) -n ip addr add $MY_CONTAINER_ETH0_IP/$MY_MASK_LEADING_BITS dev $MY_INT_INTERFACE_NAME-0
sudo nsenter -t $(docker inspect --format '{{ .State.Pid }}' $MY_CONTAINER_NAME) -n ip addr add $MY_CONTAINER_ETH1_IP/$MY_MASK_LEADING_BITS dev $MY_INT_INTERFACE_NAME-1

sudo nsenter -t $(docker inspect --format '{{ .State.Pid }}' $MY_CONTAINER_NAME) -n ip route add default via $MY_GATEWAY dev $MY_INT_INTERFACE_NAME-0

#sudo nsenter -t $(docker inspect --format '{{ .State.Pid }}' $MY_CONTAINER_NAME) -n /sbin/sysctl -w net.ipv4.ip_forward=1
#sudo nsenter -t $(docker inspect --format '{{ .State.Pid }}' $MY_CONTAINER_NAME) -n /sbin/sysctl -w net.ipv4.conf.default.rp_filter=0
#sudo nsenter -t $(docker inspect --format '{{ .State.Pid }}' $MY_CONTAINER_NAME) -n /sbin/sysctl -w net.ipv4.conf.all.rp_filter=0
