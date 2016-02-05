""" InfluxDB Docker config generator. """


import configparser
import io
import os
import re
import subprocess


def create_config():
    """ Create a fresh InfluxDB config and patch with ENV variables if needed. """
    # Get default config from `influxd config`
    config = configparser.ConfigParser()
    config.read_string(normalize_config(influxd_config(os.getenv('INFLUXD_CUSTOM'))))
    # Patch config with any ENV variables
    patched_config = patch_config(config)
    with open(INFLUXD_CONFIG, 'w') as cfg:
        cfg.write(denormalize_config(patched_config))


def influxd_config(custom=None):
    """ Return default InfluxDB config as unicode using `influxd config`,
        or `influxd config -config` if custom path is provided. """
    cmd = [ '/usr/bin/influxd', 'config' ]
    if custom is not None and os.path.exists(custom):
        cmd += [ '-config', custom ]
    print "Generating config with `%s`" % ' '.join(cmd)
    return unicode(subprocess.check_output(cmd))


def normalize_config(config):
    """ Move orphaned config to DEFAULT. """
    orphans = re.findall('^[^\[].*?\n', config)
    for orphan in orphans:
        config = config.replace(orphan, '')
    return "  ".join(["[DEFAULT]\n"]+orphans) + config


def patch_config(config):
    """ Replace config defaults with supplied ENV values. """
    overrides = filter(lambda x: x.startswith('INFLUX___'), os.environ.keys())
    dasher = lambda x: x.replace('_', '-').replace('--', '_').lower()
    for override in overrides:
        section, option = map(dasher, override.split('___')[1:])
        value = os.getenv(override)
        config[section][option] = value
        print "Patched [ %s ] :: %s = %s" % (section, option, value)
    return config


def denormalize_config(config):
    """ Move DEFAULT back to orphan status. """
    strio = io.StringIO()
    config.write(strio)
    strio.seek(0)
    return strio.read().replace("[DEFAULT]\n", '')


def main():
    """ Generate default influxd config and replace with ENV vars if found. """
    # Generate new config from `influxd config`
    if os.path.exists(INFLUXD_CONFIG):
        print "Existing InfluxDB config found at %s" % INFLUXD_CONFIG
    else:
        print "Creating InfluxDB config at %s" % INFLUXD_CONFIG
        create_config()


if __name__ == '__main__':
    INFLUXD_CONFIG = os.environ['INFLUXD_CONFIG']
    main()
