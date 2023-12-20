#!/bin/bash

#检查 ClickHouse 版本
#clickhouse-client --version | grep -q "21.8"
#if [ $? -ne 0 ]; then
#echo "ClickHouse 的版本必须至少为 21.8"
#exit 1
#fi

创建数据库
for db in deepflow_system event ext_metrics flow_log flow_metrics flow_tag profile; do
clickhouse-client -u admin -p admin -q "CREATE DATABASE $db"
done

创建用户
clickhouse-client -u admin -p admin -q "CREATE USER admin IDENTIFIED WITH PLAINTEXT_PASSWORD BY 'admin'"
clickhouse-client -u admin -p admin -q "CREATE USER deepflow IDENTIFIED WITH PLAINTEXT_PASSWORD BY 'deepflow'"

授权账户
clickhouse-client -u admin -p admin -q "GRANT ALL ON . TO admin"
clickhouse-client -u admin -p admin -q "GRANT SELECT ON deepflow_system.* TO deepflow"
clickhouse-client -u admin -p admin -q "GRANT SELECT ON event.* TO deepflow"
clickhouse-client -u admin -p admin -q "GRANT SELECT ON ext_metrics.* TO deepflow"
clickhouse-client -u admin -p admin -q "GRANT SELECT ON flow_log.* TO deepflow"
clickhouse-client -u admin -p admin -q "GRANT SELECT ON flow_metrics.* TO deepflow"
clickhouse-client -u admin -p admin -q "GRANT SELECT ON flow_tag.* TO deepflow"
clickhouse-client -u admin -p admin -q "GRANT SELECT ON profile.* TO deepflow"
