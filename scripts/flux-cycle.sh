flux suspend hr $1 -n bigbang
flux reconcile kustomization $2 -n bigbang
flux reconcile source git $1 -n bigbang
flux resume hr $1 -n bigbang
