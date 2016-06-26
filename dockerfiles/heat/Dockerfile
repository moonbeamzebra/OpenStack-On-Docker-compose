FROM mitaka-base

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get install -y \
            heat-api \
            heat-api-cfn \
            heat-engine \
            python-heatclient

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

EXPOSE 8004
EXPOSE 8000

CMD ./wait_for_mysql.sh && ./setup.sh && sleep 5 && ./run.sh
