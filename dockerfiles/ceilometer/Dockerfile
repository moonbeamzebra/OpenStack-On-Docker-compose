FROM openstack-base

ENV DEBIAN_FRONTEND noninteractive 

RUN apt-get update && apt-get install -y ceilometer-api \
                                         ceilometer-collector \
                                         ceilometer-agent-central \
                                         ceilometer-agent-notification \
                                         ceilometer-alarm-evaluator \
                                         ceilometer-alarm-notifier \
                                         python-ceilometerclient


RUN cp /etc/ceilometer/ceilometer.conf /etc/ceilometer/ceilometer.conf.bak
RUN crudini --set /etc/ceilometer/ceilometer.conf DEFAULT rpc_backend rabbit
RUN crudini --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_userid openstack
RUN crudini --set /etc/ceilometer/ceilometer.conf DEFAULT auth_strategy keystone
RUN crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken admin_tenant_name service
RUN crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken admin_user ceilometer
RUN crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_username ceilometer
RUN crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_tenant_name service
RUN crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_endpoint_type internalURL
RUN crudini --set /etc/ceilometer/ceilometer.conf DEFAULT verbose True


ADD setup.sh setup.sh
ADD run.sh run.sh

RUN chmod +x run.sh && chmod +x setup.sh

EXPOSE 8777

CMD ./setup.sh && sleep 5 && ./run.sh
