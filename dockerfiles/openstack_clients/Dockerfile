FROM openstack-base

ENV DEBIAN_FRONTEND noninteractive 

RUN apt-get update && apt-get -y install ssh \
                                         git \
                                         python-heatclient \
					 python-ceilometerclient

ADD setup.sh setup.sh
ADD run.sh run.sh

RUN chmod +x setup.sh && chmod +x run.sh 

EXPOSE 22

CMD ./setup.sh && ./run.sh
