Ensure STF is installed with metrics and graphing enable and make sure an instance of Grafana is running in the STF namespace

Create resources
```
oc create -f deploy/datasource.yaml \
    -f deploy/qdr-servicemonitor.yml \
    -f dashboards/perftest-dashboard.yaml
```

Run Test
```
./run.sh -c 10000000
```

View results in the grafana dashboard
