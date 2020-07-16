#!/bin/bash

PODS=$(oc get pods -o jsonpath="{.items[*].metadata.name}")
podArr=($PODS)

echo "[INFO]******* Last 15 lines of POD:CONTAINER logs"
for pod in "${podArr[@]}"
do
        containers=$(oc get pod "$pod" -ojsonpath="{.spec.containers[*].name}")
        containerArr=($containers)

        for container in "${containerArr[@]}"
        do
                echo
                echo
                echo
                echo "[Container Logs]********$pod:$container"
                oc logs "$pod" -c $container | tail -n15

        done

        echo 
        echo
done
exit 0
~      
