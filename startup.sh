# Configure config
python influxd_config.py

# Start InfluxDB
echo
cat ${INFLUXD_CONFIG}
echo
echo influxd -config ${INFLUXD_CONFIG} ${INFLUXD_OPTS} $*
echo
influxd -config ${INFLUXD_CONFIG} ${INFLUXD_OPTS} $*
