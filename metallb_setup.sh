#!/bin/bash

IP_POOL_START="10.100.9.60"
IP_POOL_END="10.100.9.65"

MetalLB_RTAG=$(curl -s https://api.github.com/repos/metallb/metallb/releases/latest|grep tag_name|cut -d '"' -f 4|sed 's/v//')

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v$MetalLB_RTAG/config/manifests/metallb-native.yaml

# Wait for the controller to be ready
kubectl -n metallb-system rollout status deployment controller --timeout=180s
# Wait for the speaker to be ready
kubectl -n metallb-system rollout status daemonset speaker --timeout=180s

# Confirm all pods and services are running
kubectl -n metallb-system get all

# Define the IP address pool for MetalLB
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: cfe-pool
  namespace: metallb-system
spec:
  addresses:
  - ${IP_POOL_START}-${IP_POOL_END}
EOF

# Check if the IP address pool was created successfully
kubectl -n metallb-system get ipaddresspools

# Announce the IP address pool to make it available for use
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example-advertisement
  namespace: metallb-system
spec:
  ipAddressPools:
  - cfe-pool
EOF

# Check if the L2 advertisement was created successfully
kubectl -n metallb-system get l2advertisements

# Check if the speaker is advertising the IP address pool
kubectl -n metallb-system logs -l component=speaker -c speaker | grep "cfe-pool"

# Patch ingress-nginx-controller to use the MetalLB IP address pool
kubectl patch svc ingress-nginx-controller \
  -n ingress-nginx \
  -p "{\"spec\":{\"loadBalancerIP\":\"${IP_POOL_START}\"}}"

# Check if the ingress-nginx-controller service has the correct load balancer IP
kubectl get svc -n ingress-nginx

# Ingress resources should include the followings:
# spec:
#   ingressClassName: nginx