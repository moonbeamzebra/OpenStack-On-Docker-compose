FROM newton-base

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get install -y glance python-glanceclient python-swiftclient  python-memcache


ADD setup.sh setup.sh
ADD run.sh run.sh
ADD wait_for_ks_admin_ep.sh wait_for_ks_admin_ep.sh
ADD wait_for_mysql.sh wait_for_mysql.sh

RUN chmod +x wait_for_ks_admin_ep.sh && chmod +x wait_for_mysql.sh && chmod +x run.sh && chmod +x setup.sh

EXPOSE 9191
EXPOSE 9292

CMD ./wait_for_mysql.sh && ./setup.sh && sleep 5 && ./run.sh
