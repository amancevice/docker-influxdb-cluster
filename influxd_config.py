""" InfluxDB Docker config generator. """


import os
import subprocess


def env_override_iter():
    """ Make dict of ENV overrides. """
    cfg = {}
    rep = lambda x: x.replace("_", "-").replace("__", "_")
    for key, val in os.environ.iteritems():
        if key.startswith("INFLUX___"):
            sec, opt = [rep(x) for x in key.lower().split("___")[1:]]
            if sec not in cfg:
                cfg[sec] = {}
            cfg[sec][opt] = val
    return cfg.iteritems()


def main():
    """ Generate default influxd config and replace with ENV vars if found. """
    # Generate new config from `influxd config`
    if os.path.exists(INFLUXD_CONFIG):
        print "Existing InfluxDB config found at %s" % INFLUXD_CONFIG
    else:
        cmd = [ INFLUXD, "config" ]
        cmd += [ "-config", INFLUXD_PATCH ]
        if not os.path.exists(INFLUXD_PATCH):
            with open(INFLUXD_PATCH, "w") as pch:
                for secname, sec in env_override_iter():
                    pch.write("[%s]\n" % secname)
                    for optval in sec.iteritems():
                        pch.write("  %s = %s\n" % optval)
                    pch.write("\n")
        with open(INFLUXD_CONFIG, "w") as cfg:
            cfg.write(unicode(subprocess.check_output(cmd)))


if __name__ == "__main__":
    INFLUXD = "/usr/bin/influxd"
    INFLUXD_CONFIG = os.environ["INFLUXD_CONFIG"]
    INFLUXD_PATCH = os.environ["INFLUXD_PATCH"]
    main()
