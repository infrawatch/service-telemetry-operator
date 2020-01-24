#!/bin/sh
#set -e

# Get minishift
MINISHIFT_VER=1.34.1
MINISHIFT_NAME="minishift-${MINISHIFT_VER}-linux-amd64"
wget https://github.com/minishift/minishift/releases/download/v${MINISHIFT_VER}/${MINISHIFT_NAME}.tgz
tar -xvzf ${MINISHIFT_NAME}.tgz
cd ${MINISHIFT_NAME}

# Get KVM driver
# https://docs.okd.io/latest/minishift/getting-started/setting-up-virtualization-environment.html#kvm-driver-fedora
curl -L https://github.com/dhiltgen/docker-machine-kvm/releases/download/v0.10.0/docker-machine-driver-kvm-centos7 -o docker-machine-driver-kvm
chmod +x docker-machine-driver-kvm

# So we keep to our directory but minishift still finds docker-machine-driver
PATH=$PATH:.

# Start minishift
./minishift addons enable registry-route
./minishift addons enable admin-user
./minishift start
./minishift ssh -- sudo sysctl -w vm.max_map_count=262144