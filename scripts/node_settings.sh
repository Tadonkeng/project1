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

cat <<EOF > /tmp/00-sysctl.conf
net.ipv4.ip_forward = 1
EOF
chmod 600 /tmp/00-sysctl.conf

#Iterate over the kubernetes nodes, and set ip4 forward setting, then copy a systcl.config
# in place for doing the setting on reboot.
for NODE in `kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'`
do
ssh -i "/konvoy_setup/$CLUSTER_NAME-ssh.pem" maintuser@$NODE 'sudo autotune override sysctl:net.ipv4.ip_forward:1'
scp -i "/konvoy_setup/$CLUSTER_NAME-ssh.pem" /tmp/00-sysctl.conf maintuser@$NODE:/tmp/
ssh -i "/konvoy_setup/$CLUSTER_NAME-ssh.pem" maintuser@$NODE 'sudo cp /tmp/00-sysctl.conf /etc/sysctl.d/55-ip_forward.conf'
ssh -i "/konvoy_setup/$CLUSTER_NAME-ssh.pem" maintuser@$NODE 'sudo sysctl -w net.ipv4.ip_forward=1'
scp -i "/konvoy_setup/$CLUSTER_NAME-ssh.pem" /bootstrap/scripts/logToS3.sh maintuser@$NODE:/tmp/
ssh -i "/konvoy_setup/$CLUSTER_NAME-ssh.pem" maintuser@$NODE 'sudo cp /tmp/logToS3.sh /etc/cron.hourly/logToS3'
ssh -i "/konvoy_setup/$CLUSTER_NAME-ssh.pem" maintuser@$NODE 'sudo chmod +x /etc/cron.hourly/logToS3'

done

# Deploy Virtual Memory setting to worker nodes
# needed by sipr-pb-bootstrap ECK module
cat <<EOF > /tmp/00-vm.conf
vm.max_map_count=262144
EOF
chmod 600 /tmp/00-vm.conf
for NODE in `kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}' -l konvoy.mesosphere.com/node_pool=worker`
do
ssh -i "/konvoy_setup/$CLUSTER_NAME-ssh.pem" maintuser@$NODE 'sudo sysctl -w vm.max_map_count=262144'
scp -i "/konvoy_setup/$CLUSTER_NAME-ssh.pem" /tmp/00-vm.conf maintuser@$NODE:/tmp/
ssh -i "/konvoy_setup/$CLUSTER_NAME-ssh.pem" maintuser@$NODE 'sudo cp /tmp/00-vm.conf /etc/sysctl.d/00-vm.conf'
done
