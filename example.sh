#!/bin/bash

echo "Creating docker bridge network \"influxdb\""
docker network create --driver bridge influxdb

echo
echo "Starting leader node \"ix0\""
docker run -d --name ix0 -h ix0 --net influxdb -p 8086 -p 8083 \
    amancevice/influxdb-cluster -hostname ix0:8088

echo
echo "Starting follower node \"ix1\""
sleep 1
docker run -d --name ix1 -h ix1 --net influxdb -p 8086 -p 8083 \
    amancevice/influxdb-cluster -hostname ix1:8088 -join ix0:8088

echo
echo "Starting follower node \"ix2\""
sleep 1
docker run -d --name ix2 -h ix2 --net influxdb -p 8086 -p 8083 \
    amancevice/influxdb-cluster -hostname ix2:8088 -join ix0:8088,ix1:8088

echo
echo "Opening InfluxDB CLI (run \"show servers\" to view cluster)"
sleep 1
docker run --rm -it --net influxdb --entrypoint /usr/bin/influx \
    amancevice/influxdb-cluster -host ix0
