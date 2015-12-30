# VERSION: 0.0.1
FROM tutum/curl:trusty
MAINTAINER amancevice@cargometrics.com

# To force an update of apt-get instead of a cached version
RUN echo as of 2015-12-30
RUN apt-get update
RUN apt-get install -y python python-pip && pip install configparser

# Install InfluxDB
ENV INFLUXDB_VERSION 0.9.6.1
RUN curl -s -o /tmp/influxdb_latest_amd64.deb https://s3.amazonaws.com/influxdb/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
  dpkg -i /tmp/influxdb_latest_amd64.deb && \
  rm /tmp/influxdb_latest_amd64.deb && \
  rm -rf /var/lib/apt/lists/*

# Configuration
ENV INFLUXD_CONFIG=/etc/influxdb/influxdb.conf
ADD influxd_config.py /root/influxd_config.py
ADD startup.sh /root/startup.sh

ENTRYPOINT ["/bin/bash", "/root/startup.sh"]
