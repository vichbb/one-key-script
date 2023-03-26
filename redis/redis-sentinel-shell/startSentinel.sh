#!/bin/bash

#absolute path
BASE_DIR=$(
    cd $(dirname $0)
    pwd
)/shelldata
REDIS_PASSWORD=123456
MASTER_PORT=6379
SLAVE1_PORT=6381
SLAVE2_PORT=6382
SENTINEL1_PORT=26379
SENTINEL2_PORT=26380
SENTINEL3_PORT=26381

# create Redis and Sentinel's data and log directory
mkdir -p ${BASE_DIR}/{master,slave1,slave2,sentinel1,sentinel2,sentinel3}/{data,logs}

# configure Redis master
cat >${BASE_DIR}/master/redis.conf <<EOF
port ${MASTER_PORT}
bind 127.0.0.1
dir ${BASE_DIR}/master/data/
dbfilename dump.rdb
appendonly yes
appendfilename "appendonly.aof"
requirepass ${REDIS_PASSWORD}
masterauth ${REDIS_PASSWORD}
daemonize yes
pidfile ${BASE_DIR}/master/redis.pid
logfile ${BASE_DIR}/master/logs/redis.log
EOF

# config redis slave
for i in {1..2}; do
    SLAVE_PORT="SLAVE${i}_PORT"
    cat >${BASE_DIR}/slave${i}/redis.conf <<EOF
port ${!SLAVE_PORT}
bind 127.0.0.1
dir ${BASE_DIR}/slave${i}/data/
dbfilename dump.rdb
appendonly yes
appendfilename "appendonly.aof"
replicaof 127.0.0.1 ${MASTER_PORT}
masterauth ${REDIS_PASSWORD}
requirepass ${REDIS_PASSWORD}
daemonize yes
pidfile ${BASE_DIR}/slave${i}/redis.pid
logfile ${BASE_DIR}/slave${i}/logs/redis.log
EOF
done

# 配置哨兵
for i in {1..3}; do
    SENTINEL_PORT="SENTINEL${i}_PORT"
    cat >${BASE_DIR}/sentinel${i}/sentinel.conf <<EOF
port ${!SENTINEL_PORT}
bind 127.0.0.1
sentinel monitor mymaster 127.0.0.1 ${MASTER_PORT} 2
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 10000
sentinel auth-pass mymaster ${REDIS_PASSWORD}
daemonize yes
pidfile ${BASE_DIR}/sentinel${i}/sentinel.pid
logfile ${BASE_DIR}/sentinel${i}/logs/sentinel.log
EOF
done

# 启动Redis和Sentinel实例
redis-server ${BASE_DIR}/master/redis.conf
for i in {1..2}; do
    SLAVE_PORT="SLAVE${i}_PORT"
    redis-server ${BASE_DIR}/slave${i}/redis.conf
done
for i in {1..3}; do
    SENTINEL_PORT="SENTINEL${i}_PORT"
    redis-sentinel ${BASE_DIR}/sentinel${i}/sentinel.conf
done

echo "show redis instance"
ps -ef | grep redis
