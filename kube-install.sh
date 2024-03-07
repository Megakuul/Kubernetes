#!/bin/bash

# This bash script can be used on cloud computers to setup the kubernetes base
# After the execution, you will need to either "kubeadm init" or "kubeadm join" the node (+ install networking service)

KUBE_REPO="deb http://apt.kubernetes.io/ kubernetes-xenial main"
KUBE_CONFIG="/etc/sysctl.d/kubernetes.conf"
KUBE_MODULES="/etc/modules-load.d/k8s.conf"

apt update -y 2>/dev/null # Supress stderr so it does not block when kernel update is pending
apt upgrade -y 2>/dev/null

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "$KUBE_REPO" > /etc/apt/sources.list.d/kubernetes.list

apt update -y 2>/dev/null

apt install -y kubelet kubeadm kubectl docker.io 2>/dev/null && apt-mark hold kubelet kubeadm kubectl

cat <<EOF > "$KUBE_CONFIG"
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

cat <<EOF > "$KUBE_MODULES"
overlay
br_netfilter
EOF

modprobe overlay && modprobe br_netfilter && sysctl --system

mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml 
sed -i "s/SystemdCgroup = false/SystemdCgroup = true/g" /etc/containerd/config.toml

systemctl restart docker && systemctl enable docker

systemctl enable --now kubelet

kubeadm config images pull
