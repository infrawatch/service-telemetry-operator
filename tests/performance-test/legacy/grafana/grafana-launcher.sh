#!/bin/bash

# Launches a grafana pod with a pre-determined graph format and exposes routes
# Important: this grafana instance is initialized with Admin permissions on the anonymous user
# That is, authentication is disabled 

oc delete svc/grafana \
   route/grafana \
   deployment/grafana-deployment \
   configmap/grafana-config \
   configmap/datasources-config

if ! oc get project openshift-monitoring; then
    echo "Error: openshift monitoring does not exist in cluster. Make sure monitoring is enabled" 1>&2
    exit 1
fi

OCP_PASS=$(oc get secret -n openshift-monitoring grafana-datasources -o jsonpath='{.data.prometheus\.yaml}' | base64 -d |
    python -c "import sys, json; print json.load(sys.stdin)['datasources'][0]['basicAuthPassword']")
sed -e "s|<<OCP_PASS>>|${OCP_PASS}|g" ./datasource.yaml > /tmp/datasource.yaml

oc create configmap grafana-config --from-file grafana.ini
oc create configmap datasources-config --from-file /tmp/datasource.yaml
oc create -f grafana-service.yml
oc create -f grafana-route.yml
oc create -f grafana-deploy.yml

# First the deployment will say it's Running!
oc rollout status deployment/grafana-deployment

# Then the pod will say it's ready (it will be a lie)
while oc get pod -l app=grafana -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}' | grep False; do
    oc get pod -l app=grafana
    sleep 3
done

# Finally the logs will say it's listening - Hi Grafana!
pod=$(oc get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}')
echo -n "Waiting for grafana to be listening"
while ! oc logs $pod | grep -o "HTTP Server Listen"; do echo ...; done

if ! GRAF_HOST=$(oc get routes --field-selector metadata.name=grafana -o jsonpath="{.items[0].spec.host}") 2> /dev/null; then 
    echo "Error: cannot find Grafana instance in cluster." 1>&2
    exit 1
fi

printf "\n*** Creating new dashboards in Grafana ***\n"
curl -d "{\"overwrite\": true, \"dashboard\": $(cat perftest-dashboard.json)}" \
    -H 'Content-Type: application/json' "$GRAF_HOST/api/dashboards/db"
echo
curl -d "{\"overwrite\": true, \"dashboard\": $(cat prom2-dashboard.json)}" \
    -H 'Content-Type: application/json' "$GRAF_HOST/api/dashboards/db"

printf "\nGraphing dashboard available at: \n"
oc get routes --field-selector metadata.name=grafana -o jsonpath="{.items[0].spec.host}"
printf "\n"
