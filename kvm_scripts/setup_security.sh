
source ~/demo-openrc.sh


ssh-keygen -q -N ""
nova keypair-add --pub-key ~/.ssh/id_rsa.pub mykey

nova secgroup-create ALL "ALL ingress"
nova secgroup-add-rule ALL icmp -1 -1 0.0.0.0/0
nova secgroup-add-rule ALL tcp 1 65535 0.0.0.0/0
nova secgroup-add-rule ALL udp 1 65535 0.0.0.0/0


