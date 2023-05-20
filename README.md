# Kubernetes Setup on Ubuntu 22.10 (with Containerd)

This guide explains the steps to set up a Kubernetes cluster with one master and one node on Ubuntu 22.10.

## Prerequisites

- Two machines running Ubuntu 22.10 (one as master and the other as node)
- Both machines should be able to communicate with each other over the network.

## Steps

### On Both Master and Node

#### Step 1: Update the System

Update system

```bash
sudo apt update
sudo apt upgrade -y
```

Add Kubernetes Repository

```bash
sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

Install Kubernetes Services and set them on hold

```bash
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

Disable Swap (temporary)

```bash
sudo swapoff -a
```

To ensure swap remains off after reboot, edit /etc/fstab and comment out any swap lines

```bash
sudo nano /etc/fstab
```

Enable overlay and br_netfilter kernel modules (overlay allows multiple directories to be mounted as one, netfilter enables some network features, e.g. ability to bridge IP traffic)

```bash
# Enable the modules once
sudo modprobe overlay
sudo modprobe br_netfilter

# Configure IP forwarding and iptables
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# Configure persistent loading of the modules
sudo tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

# Apply config
sudo sysctl --system
```

Add Containerd Repository

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
```

Install Containerd

```bash
sudo apt update
sudo apt install -y containerd.io
```

Or alternative just install Docker (that also uses Containerd)

```bash
sudo apt install -y docker.io
```

Set default Containerd configuration (without that Kubeadm can sometimes not access the containerd rpc api)

```bash
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
```

Restart and enable Containerd

```bash
sudo systemctl restart containerd
sudo systemctl enable containerd
```

Enable Kubelet and pull required images

```bash
sudo systemctl enable kubelet
sudo kubeadm config images pull
```

### On Master

Initialize Kubernetes

```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```

Get the token (if you lost the initial one)

```bash
sudo kubeadm token create
```

Reset Kubernetes initialization

```bash
sudo kubeadm reset
```

Setup Kubectl

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Install Pod Network (e.g. flannel)

```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

Check Network

```bash
kubectl get pods -n kube-flannel
```

### On Node

To join the node to the cluster, you'll use the kubeadm join command that was output at the end of the initialisation of the master. The command will look something like this

```bash
kubeadm join --token <token> <master-ip>:<master-port> --discovery-token-ca-cert-hash sha256:<hash> --cri-socket /run/containerd/containerd.sock
```


### Debugging

If the kube-api server is down you can checkout the pods by using the crictl tool

To use this you first need to add these lines (if you use containerd):

```bash
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 2
debug: true
pull-image-on-create: false
```

To the /etc/crictl.yaml config file