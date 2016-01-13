FROM openstack-base

ENV DEBIAN_FRONTEND noninteractive 

RUN apt-get install -y openstack-dashboard

ADD run.sh run.sh
ADD setup.sh setup.sh

RUN chmod +x run.sh && chmod +x setup.sh

EXPOSE 80

CMD ./setup.sh && sleep 5 && ./run.sh
