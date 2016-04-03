FROM ubuntu:14.04
MAINTAINER amancevice@cargometrics.com

RUN echo as of 2016-04-01 && \
    apt-get update && \
    apt-get install -y python wget

EXPOSE 8083 8086 8086/udp 8088 8091

# Install InfluxDB
ENV INFLUXDB_VERSION=0.11.1-1 \
    INFLUXD_CONFIG=/etc/influxdb/influxdb.conf \
    INFLUXD_PATCH=/root/influxdb.conf.patch \
    INFLUX___META___DIR='"/root/.influxdb/meta"' \
    INFLUX___DATA___DIR='"/root/.influxdb/data"' \
    INFLUX___DATA___WAL_DIR='"/root/.influxdb/wal"' \
    INFLUX___HINTED_HANDOFF___DIR='"/root/.influxdb/hh"' \
    INFLUX___HINTED_HANDOFF___ENABLED=true
RUN wget https://s3.amazonaws.com/influxdb/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
    sudo dpkg -i influxdb_${INFLUXDB_VERSION}_amd64.deb && \
    rm /influxdb_${INFLUXDB_VERSION}_amd64.deb && \
    mv ${INFLUXD_CONFIG} ${INFLUXD_CONFIG}.install

# Startup
COPY influxd_config.py startup.sh /root/
WORKDIR /root
ENTRYPOINT [ "/bin/bash", "/root/startup.sh" ]
