#!/bin/bash
NODE_ID=${1:-beegfs-mgmtd}

READY_FILE=/data/.ready
ACTIVE_FILE=/data/.active
DATA_PATH=/data/beegfs/test
WAIT_INTERVAL=1

echo "Waiting for filesystem to become ready..."
until [ -f "${READY_FILE}" ]; do
    sleep ${WAIT_INTERVAL}
done

touch ${ACTIVE_FILE}

if [ ! -f "${DATA_PATH}/format.conf" ]; then
    echo "Data path ${DATA_PATH} needs initialisation..."
    /opt/beegfs/sbin/beegfs-setup-mgmtd -C -p ${DATA_PATH} -S ${NODE_ID}
fi

echo "Starting BeeGFS..."

/opt/beegfs/sbin/beegfs-mgmtd \
    storeMgmtdDirectory="${DATA_PATH}/" \
    storeAllowFirstRunInit=false \
    runDaemonized=False \
    logLevel=3 &

BEEGFS_PID=${!}

while [ -f "${READY_FILE}" ] && (kill -0 ${BEEGFS_PID} 2>/dev/null); do
    echo "BeeGFS Running..."
    sleep ${WAIT_INTERVAL}
done

echo "BeeGFS died or ready marker ${READY_FILE} removed, stopping..."
kill -15 ${BEEGFS_PID} 2>/dev/null || echo "Unable to send kill to PID ${BEEGFS_PID}, maybe it's already stopped"

echo "BeeGFS stopped, removing active marker"
rm -f ${ACTIVE_FILE}