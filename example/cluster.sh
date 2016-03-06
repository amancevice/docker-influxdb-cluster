#!/bin/bash

version=0.10.2

echo "Creating docker bridge network \"influxdb\""
docker network create --driver bridge influxdb

echo
echo "Starting node \"ix0\""
docker run --detach --name ix0 \
    --env INFLUX___META___BIND_ADDRESS='"ix0:8088"' \
    --env INFLUX___META___HTTP_BIND_ADDRESS='"ix0:8091"' \
    --env INFLUX___HTTP___BIND_ADDRESS='"ix0:8086"' \
    --hostname ix0 \
    --net influxdb \
    --publish 8083 \
    --publish 8086 \
    --publish 8088 \
    --publish 8091 \
    amancevice/influxdb-cluster:$version

echo
echo "Starting node \"ix1\""
sleep 1
docker run --detach --name ix1 \
    --env INFLUX___META___BIND_ADDRESS='"ix1:8088"' \
    --env INFLUX___META___HTTP_BIND_ADDRESS='"ix1:8091"' \
    --env INFLUX___HTTP___BIND_ADDRESS='"ix1:8086"' \
    --hostname ix1 \
    --net influxdb \
    --publish 8083 \
    --publish 8086 \
    --publish 8088 \
    --publish 8091 \
    amancevice/influxdb-cluster:$version -join ix0:8091

echo
echo "Starting node \"ix2\""
sleep 1
docker run --detach --name ix2 \
    --env INFLUX___META___BIND_ADDRESS='"ix2:8088"' \
    --env INFLUX___META___HTTP_BIND_ADDRESS='"ix2:8091"' \
    --env INFLUX___HTTP___BIND_ADDRESS='"ix2:8086"' \
    --hostname ix2 \
    --net influxdb \
    --publish 8083 \
    --publish 8086 \
    --publish 8088 \
    --publish 8091 \
    amancevice/influxdb-cluster:$version -join ix0:8091

echo
echo "Starting node \"ix3\""
sleep 1
docker run --detach --name ix3 \
    --env INFLUX___META___ENABLED=false \
    --env INFLUX___META___BIND_ADDRESS='"ix3:8088"' \
    --env INFLUX___META___HTTP_BIND_ADDRESS='"ix3:8091"' \
    --env INFLUX___HTTP___BIND_ADDRESS='"ix3:8086"' \
    --hostname ix3 \
    --net influxdb \
    --publish 8083 \
    --publish 8086 \
    --publish 8088 \
    --publish 8091 \
    amancevice/influxdb-cluster:$version -join ix0:8091

echo
echo "Starting node \"ix4\""
sleep 1
docker run --detach --name ix4 \
    --env INFLUX___META___ENABLED=false \
    --env INFLUX___META___BIND_ADDRESS='"ix4:8088"' \
    --env INFLUX___META___HTTP_BIND_ADDRESS='"ix4:8091"' \
    --env INFLUX___HTTP___BIND_ADDRESS='"ix4:8086"' \
    --hostname ix4 \
    --net influxdb \
    --publish 8083 \
    --publish 8086 \
    --publish 8088 \
    --publish 8091 \
    amancevice/influxdb-cluster:$version -join ix0:8091

echo
echo "SHOW SERVERS:"
sleep 1
docker run --rm -it --net influxdb --entrypoint /usr/bin/influx \
    amancevice/influxdb-cluster:$version -host ix0 -execute "SHOW SERVERS"

# Cleanup
echo "Removed node \"$(docker rm -f ix0)\""
echo "Removed node \"$(docker rm -f ix1)\""
echo "Removed node \"$(docker rm -f ix2)\""
echo "Removed node \"$(docker rm -f ix3)\""
echo "Removed node \"$(docker rm -f ix4)\""
docker network rm influxdb
echo "Removed network \"influxdb\""
