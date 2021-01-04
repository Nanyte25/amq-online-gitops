export PGO_OPERATOR_NAMESPACE=pgo
export PGO_VERSION=v4.5.0

curl https://raw.githubusercontent.com/CrunchyData/postgres-operator/${PGO_VERSION}/deploy/install-bootstrap-creds.sh > install-bootstrap-creds.sh
curl https://raw.githubusercontent.com/CrunchyData/postgres-operator/${PGO_VERSION}/installers/kubectl/client-setup.sh > client-setup.sh

chmod +x install-bootstrap-creds.sh client-setup.sh

PGO_CMD=oc ./install-bootstrap-creds.sh
PGO_CMD=oc ./client-setup.sh


export PGO_APISERVER_URL="https://$(
  oc -n "$PGO_OPERATOR_NAMESPACE" get service postgres-operator \
    -o jsonpath="{.status.loadBalancer.ingress[*]['ip','hostname']}"
):8443"
