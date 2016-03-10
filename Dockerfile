FROM ubuntu:14.04
MAINTAINER amancevice@cargometrics.com

RUN echo as of 2016-02-19 && \
    apt-get update && \
    apt-get install -y python python-pip wget && pip install configparser

# Install InfluxDB
ENV INFLUXDB_VERSION=0.10.3-1 \
    INFLUXD_CONFIG=/etc/influxdb/influxdb.conf \
    INFLUXD_PATCH=/root/influxdb.conf.patch
RUN wget https://s3.amazonaws.com/influxdb/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
    sudo dpkg -i influxdb_${INFLUXDB_VERSION}_amd64.deb && \
    rm /influxdb_${INFLUXDB_VERSION}_amd64.deb && \
    mv ${INFLUXD_CONFIG} ${INFLUXD_CONFIG}.install

# Startup
COPY influxd_config.py startup.sh /root/
WORKDIR /root
ENTRYPOINT [ "/bin/bash", "/root/startup.sh" ]
