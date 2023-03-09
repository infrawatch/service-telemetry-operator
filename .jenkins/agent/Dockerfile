FROM quay.io/openshift/origin-jenkins-agent-base:latest

# pass --build-arg OC_CLIENT_VERSION=<version> to build stage to change client version
ARG OC_CLIENT_VERSION="4.12"

RUN curl -LO "https://github.com/operator-framework/operator-sdk/releases/download/v0.19.4/operator-sdk-v0.19.4-x86_64-linux-gnu" && \
    chmod +x operator-sdk-v0.19.4-x86_64-linux-gnu && mv operator-sdk-v0.19.4-x86_64-linux-gnu /usr/local/bin/operator-sdk
RUN dnf install -y ansible golang python38 && \
    dnf groupinstall -y "Development Tools" -y && \
    alternatives --set python /usr/bin/python3.8 && \
    python -m pip install openshift kubernetes "ansible-core~=2.12" && \
    ansible-galaxy collection install -f 'kubernetes.core:>=2.2.0' community.general
RUN curl -LO "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest-$OC_CLIENT_VERSION/openshift-client-linux.tar.gz" && \
    tar -xv -C /usr/local/bin -f openshift-client-linux.tar.gz
