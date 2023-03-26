#!/bin/bash

# 可配置变量
BASE_DIR=$(
    cd $(dirname $0)
    pwd
)/shelldata
REDIS_PASSWORD=123456
MASTER_PORTS=(7001 7002 7003)
SLAVE_PORTS=(7004 7005 7006)

# 创建目录结构
for i in {1..3}; do
    mkdir -p ${BASE_DIR}/{master${i},slave${i}}/{data,logs}
done

# 生成Redis节点配置文件
for i in {1..6}; do
    if [ $i -le 3 ]; then
        NODE="master${i}"
        PORT=${MASTER_PORTS[$(($i - 1))]}
    else
        NODE="slave$(($i - 3))"
        PORT=${SLAVE_PORTS[$(($i - 4))]}
    fi

    cat >${BASE_DIR}/${NODE}/redis.conf <<EOF
port ${PORT}
bind 127.0.0.1
cluster-enabled yes
cluster-config-file nodes-${PORT}.conf
cluster-node-timeout 5000
appendonly yes
appendfilename "appendonly.aof"
requirepass ${REDIS_PASSWORD}
masterauth ${REDIS_PASSWORD}
dir ${BASE_DIR}/${NODE}/data/
dbfilename dump.rdb
daemonize yes
pidfile ${BASE_DIR}/${NODE}/redis.pid
logfile ${BASE_DIR}/${NODE}/logs/redis.log
EOF
done

# 启动Redis节点
for i in {1..6}; do
    if [ $i -le 3 ]; then
        NODE="master${i}"
    else
        NODE="slave$(($i - 3))"
    fi
    redis-server ${BASE_DIR}/${NODE}/redis.conf
done

# 等待Redis启动完成
sleep 3

# 创建Redis Cluster
echo "yes" | redis-cli --cluster create "${MASTER_PORTS[@]/#/127.0.0.1:}" "${SLAVE_PORTS[@]/#/127.0.0.1:}" --cluster-replicas 1 --cluster-yes -a ${REDIS_PASSWORD}

echo "show redis instance"
ps -ef | grep redis
