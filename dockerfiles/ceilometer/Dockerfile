FROM openstack-base

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y mongodb-clients \
                                         python-pymongo

RUN apt-get install -y ceilometer-api \
                       ceilometer-collector \
                       ceilometer-agent-central \
                       ceilometer-agent-notification \
                       ceilometer-alarm-evaluator \
                       ceilometer-alarm-notifier \
                       python-ceilometerclient


ADD setup.sh setup.sh
ADD run.sh run.sh
ADD wait_for_ks_admin_ep.sh wait_for_ks_admin_ep.sh
ADD wait_for_mysql.sh wait_for_mysql.sh
ADD wait_for_rabbitmq.sh wait_for_rabbitmq.sh
ADD wait_for_mongo.sh wait_for_mongo.sh
ADD wait_for_glance_api.sh wait_for_glance_api.sh
ADD wait_for_neutron_api.sh wait_for_neutron_api.sh
ADD wait_for_nova_api.sh wait_for_nova_api.sh

RUN chmod +x wait_for_ks_admin_ep.sh && \
   chmod +x wait_for_mysql.sh && \
   chmod +x wait_for_rabbitmq.sh && \
   chmod +x wait_for_mongo.sh && \
   chmod +x wait_for_glance_api.sh && \
   chmod +x wait_for_neutron_api.sh && \
   chmod +x wait_for_nova_api.sh && \
   chmod +x run.sh && \
   chmod +x setup.sh

EXPOSE 8777 

CMD ./setup.sh && sleep 5 && ./run.sh
