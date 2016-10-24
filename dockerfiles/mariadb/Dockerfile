FROM mariadb:10

COPY 99-openstack.cnf /etc/mysql/mariadb.conf.d/99-openstack.cnf

COPY setup.sh /tmp/setup.sh 

RUN chmod +x /tmp/setup.sh


CMD /tmp/setup.sh && ./docker-entrypoint.sh mysqld
