FROM openstack-base

ENV DEBIAN_FRONTEND noninteractive 

RUN apt-get install -y \
    neutron-server \
    neutron-plugin-ml2 \
    python-neutronclient

ADD run.sh run.sh
ADD setup.sh setup.sh

RUN chmod +x run.sh && chmod +x setup.sh

EXPOSE 9696

CMD ./setup.sh && sleep 5 && ./run.sh
