#!/bin/bash

# This script sets up HAProxy to forward traffic to the NGINX Ingress Controller in a Kubernetes cluster.
# cloud-provider-kind is required: https://kind.sigs.k8s.io/docs/user/loadbalancer/

LB_IP=$(kubectl get svc/ingress-nginx-controller -n ingress-nginx -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')

HA_PROXY_CONFIG=/etc/haproxy/haproxy.cfg
sudo cp "$HA_PROXY_CONFIG" /etc/haproxy/haproxy.cfg.orig

sudo bash -c "cat > $HA_PROXY_CONFIG" << EOF
global
    log /dev/log local0
defaults
    balance roundrobin
    log global
    maxconn 100
    mode tcp
    timeout connect 5s
    timeout client 500s
    timeout server 500s
listen apps
    bind 0.0.0.0:80
    server lbcontainer LB_IP:80 check
listen apps_ssl
    bind 0.0.0.0:443
    server lbcontainer LB_IP:443 check
EOF
sudo sed -i "s/LB_IP/$LB_IP/g" "$HA_PROXY_CONFIG"
