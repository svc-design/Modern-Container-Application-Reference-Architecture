#!/bin/sh
/usr/bin/prometheus --config.file=/etc/prometheus/prometheus-transfer.yml --web.listen-address="0.0.0.0:9092" --web.enable-lifecycle --storage.tsdb.path="/opt/prometheus/data/"
