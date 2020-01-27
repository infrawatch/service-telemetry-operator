#!/bin/sh
#set -e

# OC command line tools
OC_VER=v3.11.0
OC_HASH=0cbc58b
OC_NAME="openshift-origin-client-tools-${OC_VER}-${OC_HASH}-linux-64bit"

wget https://github.com/openshift/origin/releases/download/${OC_VER}/${OC_NAME}.tar.gz
tar -xvzf ${OC_NAME}.tar.gz
sudo mv ${OC_NAME}/oc /usr/local/bin/

sudo bash -c 'cat > /etc/docker/daemon.json <<EOF
{
    "registry-mirrors": ["https://mirror.gcr.io"],
    "mtu": 1460,
    "insecure-registries": ["172.30.0.0/16"]
}
EOF'

# Start the containerized openshift
sudo systemctl restart docker.service
sudo sysctl -w vm.max_map_count=262144
oc cluster up --public-hostname=$(hostname) #--base-dir /var/lib/minishift

