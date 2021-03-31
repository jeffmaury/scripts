#!/bin/bash

checkDeployment() {
  echo "Checking deployment $1"
  local nb=`kubectl get pods -n $1 --no-headers --ignore-not-found | wc -l`
  echo -n "Waiting for pods to show up "
  while [ "$nb" = "0" ]
  do
    echo -n "."
	sleep 1
	nb=`kubectl get pods -n $1 --no-headers | wc -l`
  done
  echo
  nb=`kubectl get pods -n $1 --no-headers --ignore-not-found | grep -v Running | grep -v Completed | wc -l`
  while [ "$nb" != "0" ]
  do
    echo -ne "$nb pods not yet started\r"
	sleep 1
	nb=`kubectl get pods -n $1 --no-headers | grep -v Running | grep -v Completed | wc -l`
  done
  echo
}
minikube start -p knative --cpus=2
minikube profile knative
#minikube addons enable registry kubectl get pods -n knative-serving --no-headers | grep -v Running | wc -l
kubectl apply --filename https://github.com/knative/serving/releases/download/v0.21.0/serving-crds.yaml
kubectl apply --filename https://github.com/knative/serving/releases/download/v0.21.0/serving-core.yaml
checkDeployment 'knative-serving'
kubectl apply --filename https://github.com/knative/net-kourier/releases/download/v0.21.0/kourier.yaml
checkDeployment 'knative-serving'
checkDeployment 'kourier-system'
kubectl patch configmap/config-network \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"ingress.class":"kourier.ingress.networking.knative.dev"}}'
cat <<EOF | kubectl apply -n kourier-system -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kourier-ingress
  namespace: kourier-system
spec:
  rules:
  - http:
     paths:
       - path: /
         pathType: Prefix
         backend:
           service:
             name: kourier
             port:
               number: 80
EOF
  
kubectl apply --filename https://projectcontour.io/quickstart/contour.yaml
checkDeployment 'projectcontour'

kubectl apply --filename https://github.com/knative/eventing/releases/download/v0.21.3/eventing-crds.yaml
kubectl apply --filename https://github.com/knative/eventing/releases/download/v0.21.3/eventing-core.yaml
kubectl apply --filename https://github.com/knative/eventing/releases/download/v0.21.3/in-memory-channel.yaml
kubectl apply --filename https://github.com/knative/eventing/releases/download/v0.21.3/mt-channel-broker.yaml
checkDeployment 'knative-eventing'


./updateip.sh
