FROM mariadb:5

ADD mysqld_openstack.cnf /etc/mysql/conf.d/mysqld_openstack.cnf

ADD setup.sh /tmp/setup.sh 

RUN chmod +x /tmp/setup.sh


CMD /tmp/setup.sh && ./docker-entrypoint.sh mysqld
