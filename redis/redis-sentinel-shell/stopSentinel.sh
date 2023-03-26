#!/bin/bash

# need config
#absolute path
BASE_DIR=$(
    cd $(dirname $0)
    pwd
)/shelldata
echo "BASE_DIR: ${BASE_DIR}"
REDIS_PASSWORD=123456
MASTER_PORT=6379
SLAVE1_PORT=6381
SLAVE2_PORT=6382
SENTINEL1_PORT=26379
SENTINEL2_PORT=26380
SENTINEL3_PORT=26381
needRemoveAll=false

# stop Redis and Sentinel
redis-cli -p ${MASTER_PORT} -a ${REDIS_PASSWORD} shutdown
redis-cli -p ${SLAVE1_PORT} -a ${REDIS_PASSWORD} shutdown
redis-cli -p ${SLAVE2_PORT} -a ${REDIS_PASSWORD} shutdown

redis-cli -p ${SENTINEL1_PORT} shutdown
redis-cli -p ${SENTINEL2_PORT} shutdown
redis-cli -p ${SENTINEL3_PORT} shutdown

# remove Redis and Sentinel's PID file
rm -f ${BASE_DIR}/{master,slave1,slave2,sentinel1,sentinel2,sentinel3}/redis.pid
rm -f ${BASE_DIR}/{master,slave1,slave2,sentinel1,sentinel2,sentinel3}/sentinel.pid
if [[ $needRemoveAll == true ]]; then
    echo "remove all data"
    rm -rf ${BASE_DIR}
fi

echo "show redis instance"
ps -ef | grep redis
