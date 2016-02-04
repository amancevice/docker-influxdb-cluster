#!/bin/bash

version=${1:-latest}

echo "Creating docker bridge network \"influxdb\""
docker network create --driver bridge influxdb

echo
echo "Starting leader node \"ix0\""
docker run --detach \
    --name ix0 \
    --hostname ix0 \
    --net influxdb \
    --publish 8086 \
    --publish 8083 \
    --env INFLUX___META___BIND_ADDRESS='"ix0:8088"' \
    --env INFLUX___META___HTTP_BIND_ADDRESS='"ix0:8091"' \
    amancevice/influxdb-cluster:$version

echo
echo "Starting follower node \"ix1\""
sleep 1
docker run --detach \
    --name ix1 \
    --hostname ix1 \
    --net influxdb \
    --env INFLUX___META___BIND_ADDRESS='"ix1:8088"' \
    --env INFLUX___META___HTTP_BIND_ADDRESS='"ix1:8091"' \
    amancevice/influxdb-cluster:$version -join ix0:8091

echo
echo "Starting follower node \"ix2\""
sleep 1
docker run --detach \
    --name ix2 \
    --hostname ix2 \
    --net influxdb \
    --env INFLUX___META___BIND_ADDRESS='"ix2:8088"' \
    --env INFLUX___META___HTTP_BIND_ADDRESS='"ix2:8091"' \
    amancevice/influxdb-cluster:$version -join ix0:8091

echo
echo "SHOW SERVERS:"
sleep 1
docker run --rm -it --net influxdb --entrypoint /usr/bin/influx \
    amancevice/influxdb-cluster:$version -host ix0 -execute "SHOW SERVERS"
