FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y \
        crudini \
        curl \
        mariadb-client \
        netcat-openbsd \
        python-mysqldb


## Get the packages
RUN apt-get install software-properties-common -y
RUN add-apt-repository cloud-archive:newton -y
RUN apt-get update -y

RUN apt-get install python-openstackclient -y

