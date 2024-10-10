#!/bin/bash
for NS in `kubectl get ns -A -o json | jq -r '.items[] | select(.metadata.labels."argocd.argoproj.io/instance" != null) | .metadata.name'` ; do
 echo $NS
 #kubectl get ns $NS
done
