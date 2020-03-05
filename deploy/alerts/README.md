# Predefined alerts

These alarming rules come in two files described in the following

## alerts.yaml
These alarms are triggered by a substantial change (over a certain
amount of standard deviation). This requires a bit of preparation
and also some recording rules to be generated.

## simple-comparison.yaml

These alerts are much simpler, as there are basically only comparisons
of two numbers or percentages.



## Installation

Log into OpenShift and

```
oc apply -f alerts.yaml -f simple-comparison.yaml
```
