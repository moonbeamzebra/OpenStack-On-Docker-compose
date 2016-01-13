FROM openstack-base

ENV DEBIAN_FRONTEND noninteractive 

RUN apt-get update && apt-get install -y heat-api \
                                         heat-api-cfn \
                                         heat-engine \
                                         python-heatclient \
                                         git

RUN cp /etc/heat/heat.conf /etc/heat/heat.conf.bak
RUN crudini --set /etc/heat/heat.conf DEFAULT rpc_backend rabbit
RUN crudini --set /etc/heat/heat.conf keystone_authtoken admin_tenant_name service
RUN crudini --set /etc/heat/heat.conf keystone_authtoken admin_user heat
RUN crudini --set /etc/heat/heat.conf DEFAULT verbose True
RUN crudini --set /etc/heat/heat.conf DEFAULT stack_domain_admin heat_domain_admin
RUN crudini --set /etc/heat/heat.conf DEFAULT stack_user_domain_name heat_user_domain


ADD run.sh run.sh
ADD setup.sh setup.sh

RUN chmod +x run.sh && chmod +x setup.sh

EXPOSE 8000 8004

CMD ./setup.sh && sleep 5 && ./run.sh
