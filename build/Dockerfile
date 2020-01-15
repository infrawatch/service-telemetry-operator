FROM quay.io/operator-framework/ansible-operator:v0.12.0

RUN pip3 install --user jmespath

COPY watches.yaml ${HOME}/watches.yaml
COPY roles/ ${HOME}/roles/
