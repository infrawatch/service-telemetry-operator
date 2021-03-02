Ensure STF is installed with metrics and graphing enable and make sure an instance of Grafana is running in the STF namespace

Create resources
```
OCP_PASS=$(oc get secret -n openshift-monitoring grafana-datasources -ojsonpath='{.data.prometheus\.yaml}' | base64 -d | jq -r .datasources[0].basicAuthPassword)

sed "s/OCP_PASS/$OC_PASS/" deploy/datasource.yaml | oc create -f -

oc create -f deploy/qdr-servicemonitor.yml \
    -f dashboards/perftest-dashboard.yaml
```

Run Test
```
./run.sh -c 10000000
```

View results in the grafana dashboard
