#!/bin/bash
##########################################################################################################
# Script Name: gitlab-object-storage
# Description: This script will update the gitlab-object-storage secret by removing aws_secret and aws_access
#              from all data items. It will then add "iam_user_profile: true" to the rails data item.
# Args       : None
# Author     : Jason Crothers
# Version    : 1.0.2
# Notes      : Added restart of several pods, per brian 
#              .....
#              .....
##########################################################################################################
##########################################################################################################

# Array of data items in the gitlab-object-storage secret
objStorageArray=(backups rails registry)

# Loop through existing gitlab-object-storage secret and populate seperate files based on each data item
for i in ${objStorageArray[@]}; do
  kubectl get secrets -n gitlab gitlab-object-storage -o jsonpath="{.data.$i}"|base64 -d > /tmp/${i}.txt
  sed -i '/access/d' /tmp/${i}.txt
  sed -i '/secret/d' /tmp/${i}.txt
done

# Add use_iam_profile to the rails data item
rv=$(grep iam /tmp/rails.txt)
if [[ "${rv}" == "${null}" ]]; then
    echo "use_iam_profile: true" >> /tmp/rails.txt
fi

# Update gitlab-object-storage secret
kubectl get secrets -n gitlab gitlab-object-storage -o json\
 | jq --arg back "$(cat /tmp/backups.txt|base64 -w 0)" '.data["backups"]=$back'\
 | jq --arg rails "$(cat /tmp/rails.txt|base64 -w 0)" '.data["rails"]=$rails'\
 | jq --arg reg "$(cat /tmp/registry.txt|base64 -w 0)" '.data["registry"]=$reg'\
 | kubectl apply -f -

# Remove files created in the begining of script
for i in ${objStorageArray[@]}; do
  rm -rf /tmp/${i}.txt
done

# Need to restart these pods after implementation of gitlab-object-storage-secrets
for i in runner sidekiq webservice; do
  pods=$(kubectl get pods -n gitlab | grep ${i} | awk '{print $1}')
  for j in ${pods}; do
    kubectl delete pods -n gitlab ${j}
  done
done


