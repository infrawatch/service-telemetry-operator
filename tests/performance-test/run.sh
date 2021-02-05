#!/bin/bash

COUNT=1000000
SLEEP=0
ADDRESS="127.0.0.1"
PORT="5672"

function usage {
cat << EOF
./$(basename $0) [OPTIONS]

Options
    -h  show help
    -s  number of usec to sleep between each credit interval
    -c  number of messages to send
EOF
exit 0
}

while getopts "hc:s:" o; do
    case "${o}" in 
        h)
            usage
            ;;
        c)
            COUNT=${OPTARG}
            ;;
        s)
            SLEEP=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

echo "Job sending $COUNT messages"

sed -e "s/COUNT/$COUNT/" \
    -e "s/SLEEP/-s $SLEEP/" job.yaml | oc create -f -
DONE=""
until [ "$DONE" == "1" ]; do DONE=$(oc get job generator -ojsonpath='{.status.succeeded}'); echo "waiting for job to finish"; sleep 5; done;
oc delete -f job.yaml
