#!/bin/bash

mkdir /home/git/.ssh
chmod 700 /home/git/.ssh
touch /home/git/.ssh/authorized_keys
chown -R git:git /home/git
chown -R maintuser:maintuser /home/maintuser/.ssh

rm maintuser
rm maintuser.pub
aws ec2 delete-key-pair --key-name konvoy-gitrepo-key  ; aws ec2 create-key-pair --key-name konvoy-gitrepo-key | jq -r '.KeyMaterial' > /home/maintuser/.ssh/id_rsa
ssh-keygen -f /home/maintuser/.ssh/id_rsa -y > /home/maintuser/.ssh/id_rsa.pub


chmod 600 /home/maintuser/.ssh/id_rsa
chown maintuser:maintuser /home/maintuser/.ssh/id_rsa
chmod 600 /home/maintuser/.ssh/id_rsa.pub
chown maintuser:maintuser /home/maintuser/.ssh/id_rsa.pub

cp /home/maintuser/.ssh/id_rsa.pub /home/git/.ssh/authorized_keys
chown git:git /home/git/.ssh/authorized_keys
cp /home/maintuser/.ssh/id_rsa /home/git/.ssh/id_rsa

chmod 600 /home/maintuser/.ssh/id_rsa
chmod 600 /home/git/.ssh/id_rsa
chmod 400 /home/git/.ssh/authorized_keys

yum install git -y

export BASTION_IP=`curl http://$METADATA_IP/latest/meta-data/local-ipv4`

ssh-keyscan  10.112.140.4 | grep ecdsa > ~/.ssh/known_hosts

exit

ssh -i /home/maintuser/.ssh/id_rsa git@$BASTION_IP git init /home/git/repos/sipr-pb-bootstrap.git --bare
ssh -i /home/maintuser/.ssh/id_rsa git@$BASTION_IP git clone -b master /bootstrap/sipr-pb-bootstrap/sipr-pb-bootstrap.bundle
ssh -i /home/maintuser/.ssh/id_rsa git@$BASTION_IP 'cd sipr-pb-bootstrap; git branch -a; git remote add master git@$(hostname -i):~/repos/sipr-pb-bootstrap.git'

for TUSER in maintuser git
do
  mkdir /home/$TUSER/.kube
  chmod 755 /home/$TUSER/.kube
  cp /konvoy_setup/admin.conf /home/$TUSER/.kube/config
  chown -R $TUSER:$TUSER /home/$TUSER/.kube
done


sudo -u maintuser docker load < /bootstrap/sipr-pb-bootstrap/sipr-pb-bootstrap.tar
sudo -u maintuser docker load < /bootstrap/sipr-pb-bootstrap/synker-redis-argo.tar
sudo -u maintuser docker load < /bootstrap/sipr-pb-bootstrap/synker-postgresql.tar
sudo -u maintuser docker load < /bootstrap/sipr-pb-bootstrap/sipr-pb-synker-latest.tar.gz

sudo -u maintuser docker run --network='host' sipr-pb-bootstrap:latest push -b=1
sudo -u maintuser docker run --network='host' synker:redis-argo push -b=1
sudo -u maintuser docker run --network='host' synker:postgresql push -b=1
sudo -u maintuser docker run --network='host' synker:11042020 push -b=1


/bootstrap/scripts/gitEnvironment.sh | /bootstrap/scripts/gitJinja.py --template-file /bootstrap/scripts/templates/values.yaml > /home/git/sipr-pb-bootstrap/cluster/argocd/staging/values.yaml
chown git:git /home/git/sipr-pb-bootstrap/cluster/argocd/staging/values.yaml
sudo -u git mkdir /home/git/sipr-pb-bootstrap/cluster/argocd/staging/secrets/git-creds -p
cd /home/git/sipr-pb-bootstrap/
sudo -u git cp /home/git/.ssh/id_rsa ./cluster/argocd/staging/secrets/git-creds/priv.key
sudo -u git git config --global user.email "git@localhost"
sudo -u git git config --global user.name "Git User"
sudo -u git git config --global push.default simple
sudo -u git git add ./cluster/argocd/
sudo -u git git commit -m "added git-creds and updated argocd values.yaml"
sudo -u git git push master master

cd /home/git/sipr-pb-bootstrap/cluster/istio/overlays/staging/
sudo -u git mkdir -p /home/git/sipr-pb-bootstrap/cluster/istio/overlays/staging/secrets/istio-ingressgateway-certs
sudo -u git cp /bootstrap/istio-certs/* /home/git/sipr-pb-bootstrap/cluster/istio/overlays/staging/secrets/istio-ingressgateway-certs
cd /home/git/sipr-pb-bootstrap/cluster/istio
sudo -u git git add *
sudo -u git git commit -m "added istio certs and ingress gateway patch"
sudo -u git git push master master

cd /home/git/sipr-pb-bootstrap/

#sudo -u git helm upgrade argocd vendor/argocd -i --create-namespace -n argocd --wait -f "cluster/argocd/values.yaml" -f "cluster/argocd/staging/values.yaml"
#sudo -u git kubectl create secret generic git-creds --from-file=sshPrivateKey=./cluster/argocd/staging/secrets/git-creds/priv.key -n argocd
#sudo -u git helm template bootstrap/ -f bootstrap/values/bootstrap.yaml --set "core.enabled=false" --set "global.env=staging" --set global.repoURL=git@$BASTION_IP:~/repos/sipr-pb-bootstrap.git | kubectl apply -f -


