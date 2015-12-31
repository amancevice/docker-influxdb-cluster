# InfluxDB Cluster Setup

A simplistic approach to configuring and starting InfluxDB cluster nodes.

The configuration of InfluxDB on startup is determined by two key environmental variables, `INFLUXD_CONFIG` & `INFLUXD_OPTS`, and the `CMD` passed into the Docker invocation.

The variable `INFLUXD_CONFIG` represents the path to the configuration file that `influxd` uses to bring up the node.

Additional startup options can be stored in the `INFLUXD_OPTS` variable (this is optional), or by passing them into the Docker `CMD` invocation.


## Influxd Configuration

The default behavior of the node is to create a new configuration file by executing the `influxd config` command at startup and piping the contents to `/etc/influxdb/influxdb.conf`. Altering the value of `INFLUXD_CONFIG` will change the location of this generated file.

Values in the generated file can be patched/overridden through `ENV` variables or by mounting your own configuration.


### Patching/Overriding Defaults with `ENV`

If it is the case that *most* of the default configuration is acceptable, values can be patched piecemeal by defining `ENV` variables using the naming convention `INFLUX___<section>___<option>=<value>`.

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
docker run --rm -it\
    --volume $(pwd)/example:/influxdb \
    --env INFLUXD_CONFIG=/influxdb/influxdb.conf \
    amancevice/influxdb-cluster
```


## Clustering

It would be a good idea to review the instructions on InfluxDB's documentation on [clustering](https://docs.influxdata.com/influxdb/v0.9/guides/clustering/#configuration) before continuing.

Configuring the node to start as part of a cluster can be done one of two ways: by storing clustering options in the `INFLUXD_OPTS` environmental variable or by passing them as part of the Docker `CMD` invocation. Both accomplish the same thing and it is only a matter of preference which method is used.


## Examples

Assume we have set up three EC2 instances on AWS using [InfluxDB's installation guide](https://docs.influxdata.com/influxdb/v0.9/introduction/installation/#hosting-on-aws). Having followed the instructions, assume two EBS volumes have been mounted at `/mnt/influx` and `/mnt/db`. These volumes are to be mounted to the container at the same location as the host.

**EC2 instances:**
* ix0.mycluster
* ix1.mycluster
* ix2.mycluster


### Patch the configuration

Create an Envfile that makes the [recommended patches](https://docs.influxdata.com/influxdb/v0.9/introduction/installation/#configuring-the-instance). See the example at [`./example/Envfile`](./example/Envfile):

```bash
INFLUX___META___DIR="/mnt/db/meta"
INFLUX___DATA___DIR="/mnt/db/data"
INFLUX___DATA___WAL_DIR="/mnt/influx/wal"
INFLUX___HINTED_HANDOFF___DIR="/mnt/db/hh"
```


### Bring up the first node

Bring up the first leader node in detached-mode and name it `ix0`. Expose the bind, admin, and REST ports, mount the EBS volumes, and use the above Envfile to patch the configuration. Use the `CMD` `-hostname ix0.mycluster:8088` to indicate that this node is accessible from the host `ix0.mycluster` and its bind-port is `8088`:

```bash
docker run --name ix0 -d
    -p 8088:8088 -p 8083:8083 -p 8086:8086 \
    -v /mnt/influx:/mnt/influx \
    -v /mnt/db:/mnt/db \
    --env-file ./Envfile
    amancevice/influxdb-cluster -hostname ix0.mycluster:8088
```


### Bring up the second node

The second follower node almost identically to the first node, but alter its `CMD` to join to the leader:

```bash
docker run --name ix1 -d
    -p 8088:8088 \
    -v /mnt/influx:/mnt/influx \
    -v /mnt/db:/mnt/db \
    --env-file ./Envfile
    amancevice/influxdb-cluster \
        -hostname ix1.mycluster:8088 -join ix0.mycluster:8088
```


### Bring up the third node

Bring up the third follower node following this pattern:

```bash
docker run --name ix1 -d
    -p 8088:8088 \
    -v /mnt/influx:/mnt/influx \
    -v /mnt/db:/mnt/db \
    --env-file ./Envfile
    amancevice/influxdb-cluster \
        -hostname ix2.mycluster:8088 -join ix0.mycluster:8088,ix1.mycluster:8088
```

And so on...

See the example at [`./example/cluster.sh`](./example/cluster.sh) to see how to bring up a simple cluster on your machine.
