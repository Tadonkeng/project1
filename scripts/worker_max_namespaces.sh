#!/bin/bash

if [ $# -ne 1 ]; 
    then echo "usage node_settings.sh <cluster_name>"
    exit 1
fi

CLUSTER_NAME=$1

if [ ! -f /konvoy_setup/$CLUSTER_NAME-ssh.pem ]; then
  echo "Can't find node ssh key /konvoy_setup/$CLUSTER_NAME-ssh.pem"
  exit 1
fi

# Deploy Virtual Memory setting to worker nodes
# needed by sipr-pb-bootstrap ECK module
cat <<EOF > /tmp/00-vm-namespace.conf
max_user_namespaces=100
EOF
chmod 600 /tmp/00-vm-namespaces.conf
for NODE in `kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}' -l konvoy.mesosphere.com/node_pool=worker`
do
ssh -i "/konvoy_setup/$CLUSTER_NAME-ssh.pem" maintuser@$NODE 'sudo sysctl -w user.max_user_namespaces=100'
done
