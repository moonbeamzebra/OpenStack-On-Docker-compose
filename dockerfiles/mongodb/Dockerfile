FROM mitaka-base

ENV DEBIAN_FRONTEND noninteractive


RUN apt-get update && apt-get install -y mongodb-server \
                                         mongodb-clients \
                                         python-pymongo

ADD setup.sh setup.sh
ADD run.sh run.sh
ADD wait_for_ks_admin_ep.sh wait_for_ks_admin_ep.sh
ADD wait_for_mysql.sh wait_for_mysql.sh
ADD wait_for_rabbitmq.sh wait_for_rabbitmq.sh
ADD wait_for_mongo.sh wait_for_mongo.sh

RUN chmod +x wait_for_ks_admin_ep.sh && \
    chmod +x wait_for_mysql.sh && \
    chmod +x wait_for_rabbitmq.sh && \
    chmod +x wait_for_mongo.sh && \
    chmod +x run.sh && \
    chmod +x setup.sh

EXPOSE 27017

CMD ./setup.sh && sleep 5 && ./run.sh
