FROM openstack-base

ENV DEBIAN_FRONTEND noninteractive 

RUN apt-get install -y \
    nova-api \
    nova-cert \
    nova-conductor \
    nova-consoleauth \
    nova-novncproxy \
    nova-scheduler \
    python-novaclient


ADD run.sh run.sh
ADD setup.sh setup.sh

RUN chmod +x run.sh && chmod +x setup.sh

EXPOSE 8774
EXPOSE 8775
EXPOSE 6080

CMD ./setup.sh && sleep 5 && ./run.sh
