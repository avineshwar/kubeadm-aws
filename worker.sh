#!/bin/bash -v

curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl kubernetes-cni docker.io

# Docker sets the policy for the FORWARD chain to DROP, change it back.
iptables -P FORWARD ACCEPT

name=""
while [[ -z "$name" ]]; do
    sleep 1
    name="$(hostname -f)"
done

cat <<EOF > /tmp/kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta1
kind: JoinConfiguration
discovery:
  bootstrapToken:
    token: ${k8stoken}
    unsafeSkipCAVerification: true
    apiServerEndpoint: ${masterIP}:6443
nodeRegistration:
  name: $name
  kubeletExtraArgs:
    cloud-provider: aws
    network-plugin: kubenet
    non-masquerade-cidr: 0.0.0.0/0
    node-labels: kubernetes.io/role=worker
EOF

for i in {1..50}; do kubeadm join --config=/tmp/kubeadm-config.yaml && break || sleep 15; done
