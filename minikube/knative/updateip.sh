#!/bin/bash

ksvc_domain="\"data\":{\""$(minikube ip)".nip.io\": \"\"}"
kubectl patch configmap/config-domain \
    -n knative-serving \
    --type merge \
    -p "{$ksvc_domain}"
