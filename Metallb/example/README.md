# Metallb Setup

This guide shows of a simple example of how to install and use Metallb to expose a NGINX Webserver

### Install Metallb

Install Metallb with following configurations

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.11.0/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.11.0/manifests/metallb.yaml
```