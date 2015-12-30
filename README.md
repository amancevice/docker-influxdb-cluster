# InfluxDB Cluster Setup

The `influxdb-cluster` Docker image is designed to facilitate the setup of an InfluxDB node cluster.


## Basic Usage

To start a basic standalone InfluxDB node:

```bash
docker run -d -p 8083:8083 -p 8086:8086 amancevice/influxdb-cluster
```


## Overriding Default Configuration

The `influxdb-cluster` image expects users to override default InfluxDB configurations by passing them as `ENV` variables.

To override a default configuration value, set an `ENV` var with the naming convention `INFLUX___<section>___<option>=<value>`, or the string `"INFLUX"`, followed by three underscores (`___`), the name of the ini section, three more underscores (`___`), and the name of the option.

Take the following default section:
```ini
[continuous_queries]
  log-enabled = true
  enabled = true
  recompute-previous-n = 2
  recompute-no-older-than = "10m0s"
  compute-runs-per-interval = 10
  compute-no-more-than = "2m0s"
```

Override `compute-no-more-than` by setting the `ENV` variable:

```bash
INFLUX___CONTINUOUS__QUERIES___COMPUTE_NO_MORE_THAN='"5m0s"'
```

Which yields:

```ini
[continuous_queries]
  log-enabled = true
  enabled = true
  recompute-previous-n = 2
  recompute-no-older-than = "10m0s"
  compute-runs-per-interval = 10
  compute-no-more-than = "5m0s"
```

If the section or option name contains an underscore (`_`), replace it in the `ENV` name with two underscores (`__`). Replace dashes (`-`) with a single underscore (`_`).

Override the `INFLUXD_CONFIG` variable to change where the configuration is stored.


## Create an Envfile

Creating an Envfile will help maintain node configurations. Assume we are bringing up a cluster on three AWS EC2 machines with mounted volumes, as recommended by [InfluxDB's installation guide](https://docs.influxdata.com/influxdb/v0.9/introduction/installation/#hosting-on-aws). Say two EBS volumes are mounted at `/mnt/influx` and `/mnt/db`. We will need to mount these volumes into the Docker container but for the sake of this example we will mount them to the same locations in the container.

Change the default configuration by creating an Envfile:

```bash
# ./Envfile
INFLUX___META___DIR=/mnt/db/meta
INFLUX___DATA___DIR=/mnt/db/data
INFLUX___DATA___WAL_DIR=/mnt/influx/wal
INFLUX___HINTED_HANDOFF___DIR=/mnt/db/hh
```

Now we can mount the volumes and configure InfluxDB in the container to look for them in the correct location:

```bash
docker run -d -p 8083:8083 -p 8086:8086 \
    -v /mnt/influx:/mnt/influx \
    -v /mnt/db:/mnt/db \
    --env-file ./Envfile
    amancevice/influxdb-cluster
    
```


## Clustering

If a container is being brought up as part of a cluster additional startup options can be passed directly to the run or start commands.


### Bring up the first node

```bash
docker run -d -p 8083:8083 -p 8086:8086 \
    -v /mnt/influx:/mnt/influx \
    -v /mnt/db:/mnt/db \
    --env-file ./Envfile
    amancevice/influxdb-cluster -hostname 10.10.10.10:8886
```


### Bring up the second node

```bash
docker run -d -p 8083:8083 -p 8086:8086 \
    -v /mnt/influx:/mnt/influx \
    -v /mnt/db:/mnt/db \
    --env-file ./Envfile
    amancevice/influxdb-cluster \
        -hostname 10.10.10.11:8086 -join 10.10.10.10:8086
```


### Bring up the third node

```bash
docker run -d -p 8083:8083 -p 8086:8086 \
    -v /mnt/influx:/mnt/influx \
    -v /mnt/db:/mnt/db \
    --env-file ./Envfile
    amancevice/influxdb-cluster \
        -hostname 10.10.10.12:8086 -join 10.10.10.10:8086,10.10.10.11:8086
```

And so on...

See [example.sh](./example.sh) for a working example that sets up a local cluster of three nodes.
