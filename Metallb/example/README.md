# Metallb Setup

This guide shows of a simple example of how to install and use Metallb to expose a NGINX Webserver

### Install Metallb

Install Metallb with following configurations

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.9/config/manifests/metallb-native.yaml
```

Or with Microk8s

```bash
microk8s enable metallb:<DefaultAddressPool>
```

If you already have a IP address pool (in microk8s the default is "default-addresspool") you can apply the metallb-example.yaml file

```bash
microk8s kubectl apply -f metallb-example.yaml
```

Else you can first apply a  ip-address-pool by changing the address-pool.yaml file and applying it

```bash
microk8s kubectl apply -f address-pool.yaml
```