#!/bin/bash

# 可配置变量
BASE_DIR=$(
    cd $(dirname $0)
    pwd
)/shelldata
REDIS_PASSWORD=123456
MASTER_PORTS=(7001 7002 7003)
SLAVE_PORTS=(7004 7005 7006)
needRemoveAll=false

# 停止Redis节点
for i in {1..6}; do
    if [ $i -le 3 ]; then
        NODE="master${i}"
        PORT=${MASTER_PORTS[$(($i - 1))]}
    else
        NODE="slave$(($i - 3))"
        PORT=${SLAVE_PORTS[$(($i - 4))]}
    fi
    redis-cli -h 127.0.0.1 -p ${PORT} -a ${REDIS_PASSWORD} shutdown
done

if [[ $needRemoveAll == true ]]; then
    echo "remove all data"
    rm -rf ${BASE_DIR}
fi

echo "show redis instance"
ps -ef | grep redis
