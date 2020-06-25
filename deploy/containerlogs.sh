#!/bin/bash

PODS=$(oc get pods -o jsonpath="{.items[*].metadata.name}")
podArr=($PODS)

echo "Last 5 lines of POD:CONTAINER logs"
for pod in "${podArr[@]}"
do
        containers=$(oc get pod "$pod" -ojsonpath="{.spec.containers[*].name}")
        containerArr=($containers)

        for container in "${containerArr[@]}"
        do
                echo
                echo
                echo
                echo "====================== $pod:$container ======================"
                oc logs "$pod" -c $container | tail -n5

        done

        echo 
        echo
done
exit 0
~      
