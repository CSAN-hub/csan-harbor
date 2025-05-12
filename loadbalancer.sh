#!/bin/bash

# Add haproxy load-balancer in front of k8s ingress controller

# @author  Fabrice Jammes

set -euxo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

. $DIR/conf.sh

# Warn: might not always work because it assummes the https port is the second one
http_node_port=$(kubectl get svc ingress-nginx-controller -n "$ingress_ns"  -o jsonpath="{.spec.ports[0].nodePort}")
https_node_port=$(kubectl get svc ingress-nginx-controller -n "$ingress_ns"  -o jsonpath="{.spec.ports[1].nodePort}")

# Get master node IP
node_ip=$(kubectl get nodes -o=jsonpath='{.items[0].status.addresses[0].address}')

# Check if podman is installed
if ! command -v haproxy &> /dev/null
then
    echo "haproxy could not be found and will be installed"
    sudo apt install -y haproxy
fi

HA_PROXY_CONFIG=/etc/haproxy/haproxy.cfg
sudo cp "$HA_PROXY_CONFIG" /etc/haproxy/haproxy.cfg.$( date +%Y%m%d-%H%M%S )

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
    server lbcontainer NODE_IP:HTTP_NODE_PORT check
listen apps_ssl
    bind 0.0.0.0:443
    server lbcontainer NODE_IP:HTTPS_NODE_PORT check
EOF
sudo sed -i "s/NODE_IP/$node_ip/g" "$HA_PROXY_CONFIG"
sudo sed -i "s/HTTP_NODE_PORT/$http_node_port/g" "$HA_PROXY_CONFIG"
sudo sed -i "s/HTTPS_NODE_PORT/$https_node_port/g" "$HA_PROXY_CONFIG"
sudo systemctl restart haproxy
sudo systemctl enable haproxy
sudo systemctl status haproxy


# Configure DNS

# Check if $harbor_domain is resolvable
if ! host "$harbor_domain" > /dev/null 2>&1; then
    echo "The domain $harbor_domain is not resolvable. Adding it to /etc/hosts file."
    sudo $(which txeh) remove host "$harbor_domain"
    sudo $(which txeh) add 127.0.0.1 "$harbor_domain"
fi

harbor_url="https://$harbor_domain"
ink "Login in to Harbor at URL $harbor_url with creds 'admin/Harbor12345'"
curl -k -L "$harbor_url"

