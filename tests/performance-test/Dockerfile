#--- Build SAF performance test ---
FROM golang:1.13
WORKDIR /go/src/performance-test/

COPY ./main.go ./parser.go ./

RUN go get gopkg.in/yaml.v2 && \
    go get github.com/grafana-tools/sdk && \
    go build -o main && \
    mv main /tmp/

#--- Create performance test layer ---
FROM tripleomaster/centos-binary-collectd:current-tripleo-rdo
USER root

RUN yum install golang -y && \
    yum update-minimal --security -y && \ 
                                          #issue with full update:
                                          #https://github.com/redhat-service-assurance/telemetry-framework/issues/81
    yum clean all

COPY --from=0 /tmp/main /performance-test/exec/main
COPY deploy/scripts/launch-test.sh /performance-test/exec/launch-test.sh
