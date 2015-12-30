# Configure config
/usr/bin/env python /root/influxd_config.py > ${INFLUXD_CONFIG}

# Start InfluxDB
cat ${INFLUXD_CONFIG}
echo
echo influxd -config ${INFLUXD_CONFIG} $*
echo
influxd -config ${INFLUXD_CONFIG} $*
