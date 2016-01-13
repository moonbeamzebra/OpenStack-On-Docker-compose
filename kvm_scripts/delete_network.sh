source ~/demo-openrc.sh




neutron router-interface-delete router private

#neutron router-gateway-set router public

neutron router-delete router

neutron subnet-delete private 

neutron net-delete private


source ~/admin-openrc.sh

neutron subnet-delete public

neutron net-delete public

