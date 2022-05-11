FROM quay.io/openshift/origin-jenkins-agent-base:latest
RUN curl -LO "https://github.com/operator-framework/operator-sdk/releases/download/v0.19.4/operator-sdk-v0.19.4-x86_64-linux-gnu" && \
    chmod +x operator-sdk-v0.19.4-x86_64-linux-gnu && mv operator-sdk-v0.19.4-x86_64-linux-gnu /usr/local/bin/operator-sdk
RUN dnf install -y ansible golang && \
    dnf groupinstall -y "Development Tools" -y && \
    ansible-galaxy collection install community.kubernetes && \
    python -m pip install openshift kubernetes
