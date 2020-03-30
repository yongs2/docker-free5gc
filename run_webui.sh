#!/bin/sh

WORK_DIR=/root/free5gc/webconsole

cd ${WORK_DIR}

# run websonsole
echo "run webconsole backend"
${WORK_DIR}/webconsole &

sleep 1

# run frontend
echo "run frontend"
yarn start
