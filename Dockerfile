FROM ubuntu:14.04
MAINTAINER amancevice@cargometrics.com

RUN echo as of 2015-12-30 && \
    apt-get update && \
    apt-get install -y python python-pip wget && pip install configparser

# Install InfluxDB
ENV INFLUXDB_VERSION=0.10.0-1 \
    INFLUXD_CONFIG=/etc/influxdb/influxdb.conf
RUN wget https://s3.amazonaws.com/influxdb/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
    sudo dpkg -i influxdb_${INFLUXDB_VERSION}_amd64.deb && \
    rm /influxdb_${INFLUXDB_VERSION}_amd64.deb && \
    mv ${INFLUXD_CONFIG} ${INFLUXD_CONFIG}.install

# Startup
ADD influxd_config.py /root/influxd_config.py
ADD startup.sh /root/startup.sh
WORKDIR /root
ENTRYPOINT [ "/bin/bash", "/root/startup.sh" ]
