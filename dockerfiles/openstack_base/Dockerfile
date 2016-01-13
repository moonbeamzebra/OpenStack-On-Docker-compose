FROM ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y \
        crudini \
        curl \
        mariadb-client-5.* \
        python-mysqldb


## Get the packages
RUN apt-get install software-properties-common -y
RUN add-apt-repository cloud-archive:liberty -y
RUN apt-get update -y


RUN apt-get install -y python-openstackclient
