#!/usr/bin/env python


""" InfluxDB Docker config generator. """


import configparser
import io
import os
import re
import subprocess


def influxd_config(influxd):
    """ Return default InfluxDB config from `influxd config`. """
    return unicode(subprocess.check_output([influxd, 'config']))


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
        config[section][option] = os.getenv(override)


def denormalize_config(config):
    """ Move DEFAULT back to orphan status. """
    strio = io.StringIO()
    config.write(strio)
    strio.seek(0)
    return strio.read().replace("[DEFAULT]\n", '')


def main():
    """ Generate default influxd config and replace with ENV vars if found. """
    influxd = subprocess.check_output(['/usr/bin/which', 'influxd']).strip()
    config = configparser.ConfigParser()
    config.read_string(normalize_config(influxd_config(influxd)))
    patch_config(config)

    print denormalize_config(config)


if __name__ == '__main__':
    main()