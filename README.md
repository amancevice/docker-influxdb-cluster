# InfluxDB Cluster Setup

A simplistic approach to configuring and starting InfluxDB cluster nodes.

The configuration of InfluxDB on startup is determined by two key environmental variables, `INFLUXD_CONFIG` & `INFLUXD_OPTS`, and the `CMD` passed into the Docker invocation.

The variable `INFLUXD_CONFIG` represents the path to the configuration file that `influxd` uses to bring up the node.

Additional startup options can be stored in the `INFLUXD_OPTS` variable (this is optional), or by passing them into the Docker `CMD` invocation.


## Influxd Configuration

The default behavior of the node is to create a new configuration file by executing the `influxd config` command at startup and piping the contents to `/etc/influxdb/influxdb.conf`. Altering the value of `INFLUXD_CONFIG` will change the location of this generated file.

Values in the generated file can be patched/overridden through `ENV` variables or by mounting your own configuration.


### Patching/Overriding defaults with a partial config

As of InfluxDB `0.10.0` the `influxd config` command accepts a `-config` option to submit a partial config that will overwrite the default generation. Mounting a custom partial config can be used to patch defaults without writing an entire config file.

Consider the following partial custom config:

```ini
[meta]
  dir = "/mnt/db/meta"

[data]
  dir = "/mnt/db/data"
  wal-dir = "/mnt/influx/wal"

[hinted-handoff]
  dir = "/mnt/db/hh"
```

Mounting this file to `/root/influxdb.conf.custom` when creating/starting the container will patch the default config with the values provided. Partial custom configurations can be mounted elsewhere but the value of the `ENV` variable `INFLUXD_CUSTOM` must be changed in addition to reflect the non-standard location of the custom partial file.


### Patching/Overriding Defaults with `ENV`

If it is the case that *most* of the default configuration is acceptable, values can be patched piecemeal by defining `ENV` variables using the naming convention `INFLUX___<section>___<option>=<value>`. In many cases, passing `ENV` variables is easier than mounting custom configs as well. Passing `ENV` variables in this manner overrides custom partial files as described above.

The variable must start with the string `"INFLUX"`, followed by three underscores (`___`), the name of the configuration section, three more underscores (`___`), and the name of the option.

If the section or option name contains an underscore (`_`), replace it in the `ENV` name with two underscores (`__`). Replace dashes (`-`) with a single underscore (`_`).

Take the following configuration section:

```ini
[continuous_queries]
  ...
  compute-no-more-than = "2m0s"
```

Override `compute-no-more-than` by setting the `ENV` variable:

```bash
INFLUX___CONTINUOUS__QUERIES___COMPUTE_NO_MORE_THAN="5m0s"
```

Which yields:

```ini
[continuous_queries]
  ...
  compute-no-more-than = "5m0s"
```

**Suggestion:** Store your patched options in an Envfile to make container invocation simpler.


### Mounting A Custom Configuration

Instead of patching individual options, an entire configuration can be mounted into the container. Ensure that the location of the mounted config is reflected in the `INFLUXD_CONFIG` variable:

```bash
docker run --rm --interactive --tty \
    --env INFLUXD_CONFIG=/influxdb/influxdb.conf \
    --volume $(pwd)/example:/influxdb \
    amancevice/influxdb-cluster
```


## Clustering

It would be a good idea to review the instructions on InfluxDB's documentation on [clustering](https://docs.influxdata.com/influxdb/v0.10/guides/clustering/#configuration) before continuing.


### Example Cluster Setup

Assume we have set up three EC2 instances on AWS using [InfluxDB's installation guide](https://docs.influxdata.com/influxdb/v0.10/introduction/installation/#hosting-on-aws). Having followed the instructions, assume two EBS volumes have been mounted at `/mnt/influx` and `/mnt/db`. These volumes are to be mounted to the container at the same location as the host.

Assume that the addressable hostnames for each of the three nodes are as follows:
* ix0.mycluster
* ix1.mycluster
* ix2.mycluster


### Patch the configuration

Create an Envfile for each node in the cluster that makes the [recommended patches](https://docs.influxdata.com/influxdb/v0.10/introduction/installation/#configuring-the-instance). See the example at [`./example/Envfile`](./example/Envfile):

```bash
INFLUX___META___DIR="/mnt/db/meta"
INFLUX___DATA___DIR="/mnt/db/data"
INFLUX___DATA___WAL_DIR="/mnt/influx/wal"
INFLUX___HINTED_HANDOFF___DIR="/mnt/db/hh"
```

As of InfluxDB `0.10.0`, you *must* patch the `[meta]` section's values for `bind-address` and `http-bind-address` as well as the `[http]` `bind-address` option. We will use the values `<hostname>:8088`, `<hostname>:8091`, and `<hostname>:8086`, respectively.

**NOTE** the hostnames used must be accessible from the other nodes in the cluster. Additionally, we **must** assign the true hostname to the container using the `--hostname` option of `docker run`/`docker create`.


### Bring up the first node

Update the Envfile with the patched bind addresses or pass them in directly:

```bash
docker run --detach --name ix0 \
    --env INFLUX___META___BIND_ADDRESS='"ix0.mycluster:8088"' \
    --env INFLUX___META___HTTP_BIND_ADDRESS='"ix0.mycluster:8091"' \
    --env INFLUX___HTTP___BIND_ADDRESS='"ix0.mycluster:8086"' \
    --env-file ./Envfile \
    --hostname ix0.mycluster \
    --publish 8083:8083 \
    --publish 8086:8086 \
    --publish 8088:8088 \
    --publish 8091:8091 \
    --volume /mnt/db:/mnt/db \
    --volume /mnt/influx:/mnt/influx \
    amancevice/influxdb-cluster
```


### Bring up the second node

The second follower node is started almost identically to the first node, altering the `CMD` to join to the leader on port `8091`:

```bash
docker run --detach --name ix1 \
    --env INFLUX___META___BIND_ADDRESS='"ix1.mycluster:8088"' \
    --env INFLUX___META___HTTP_BIND_ADDRESS='"ix1.mycluster:8091"' \
    --env INFLUX___HTTP___BIND_ADDRESS='"ix1.mycluster:8086"' \
    --env-file ./Envfile \
    --hostname ix1.mycluster \
    --publish 8083:8083 \
    --publish 8086:8086 \
    --publish 8088:8088 \
    --publish 8091:8091 \
    --volume /mnt/db:/mnt/db \
    --volume /mnt/influx:/mnt/influx \
    amancevice/influxdb-cluster -join ix0.mycluster:8091
```


### Bring up the third node

Bring up the third follower node following this pattern:

```bash
docker run --detach --name ix2 \
    --env INFLUX___META___BIND_ADDRESS='"ix2.mycluster:8088"' \
    --env INFLUX___META___HTTP_BIND_ADDRESS='"ix2.mycluster:8091"' \
    --env INFLUX___HTTP___BIND_ADDRESS='"ix2.mycluster:8086"' \
    --env-file ./Envfile \
    --hostname ix2.mycluster \
    --publish 8083:8083 \
    --publish 8086:8086 \
    --publish 8088:8088 \
    --publish 8091:8091 \
    --volume /mnt/db:/mnt/db \
    --volume /mnt/influx:/mnt/influx \
    amancevice/influxdb-cluster -join ix0.mycluster:8091
```

And so on...

See the example at [`./example/cluster.sh`](./example/cluster.sh) to see how to bring up a simple cluster on your machine.
