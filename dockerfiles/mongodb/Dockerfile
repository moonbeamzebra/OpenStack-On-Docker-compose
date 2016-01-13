FROM openstack-base

ENV DEBIAN_FRONTEND noninteractive 

RUN apt-get update && apt-get install -y mongodb-server \
                                         mongodb-clients \
                                         python-pymongo

RUN cp /etc/mongodb.conf /etc/mongodb.conf.bak
RUN sed -i "s/bind_ip/#bind_ip/g" /etc/mongodb.conf
RUN sed -i "s/smallfiles/#smallfiles/g" /etc/mongodb.conf
RUN echo "bind_ip = 0.0.0.0" >> /etc/mongodb.conf
RUN echo "smallfiles = true" >> /etc/mongodb.conf

ADD run.sh run.sh
ADD setup.sh setup.sh
ADD init.sh init.sh

RUN chmod +x run.sh && chmod +x setup.sh && chmod +x init.sh

EXPOSE 27017

CMD ./setup.sh && sleep 5 && ./run.sh
