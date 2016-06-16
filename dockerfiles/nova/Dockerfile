FROM openstack-base

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get install -y \
  nova-api \
  nova-conductor \
  nova-consoleauth \
  nova-novncproxy \
  nova-scheduler

ADD setup.sh setup.sh
ADD run.sh run.sh
ADD wait_for_ks_admin_ep.sh wait_for_ks_admin_ep.sh
ADD wait_for_mysql.sh wait_for_mysql.sh
ADD wait_for_rabbitmq.sh wait_for_rabbitmq.sh

RUN chmod +x wait_for_ks_admin_ep.sh && \
    chmod +x wait_for_mysql.sh && \
    chmod +x wait_for_rabbitmq.sh && \
    chmod +x run.sh && \
    chmod +x setup.sh

EXPOSE 8774
EXPOSE 8775
EXPOSE 6080

CMD ./wait_for_mysql.sh && ./setup.sh && sleep 5 && ./run.sh
