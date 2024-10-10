#!/bin/bash
# Ensure to change the client secret before executing this script.
# Get new client secret from Keycloack-->Argocd-->Credentials-->Secret

kubectl get secret argocd-secret -n argocd -o json | jq --arg foo "$(echo -n 56375247-403f-4906-8130-292b5ac8d813 | base64)" '.data["oidc.keycloak.clientSecret"]=$foo' | kubectl apply -f -
