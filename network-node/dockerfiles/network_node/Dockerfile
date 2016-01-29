FROM openstack-base

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y \
                      neutron-plugin-ml2 \
                      neutron-plugin-openvswitch-agent \
                      neutron-l3-agent \
                      neutron-dhcp-agent \
                      neutron-metadata-agent


ADD setup.sh setup.sh
ADD run.sh run.sh
ADD wait_for_ks_admin_ep.sh wait_for_ks_admin_ep.sh
ADD wait_for_mysql.sh wait_for_mysql.sh
ADD wait_for_rabbitmq.sh wait_for_rabbitmq.sh

RUN chmod +x wait_for_ks_admin_ep.sh && \
    chmod +x wait_for_mysql.sh && \
    chmod +x wait_for_rabbitmq.sh && \
    chmod +x run.sh && chmod +x setup.sh

CMD ./setup.sh && sleep 5 && ./run.sh
