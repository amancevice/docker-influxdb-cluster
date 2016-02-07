# Configure config
python influxd_config.py
cmd="influxd -config ${INFLUXD_CONFIG} ${INFLUXD_OPTS} $*"

# Start InfluxDB
echo
cat ${INFLUXD_CONFIG}
echo
echo $cmd
echo
$cmd
