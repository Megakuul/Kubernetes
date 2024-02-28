# Setting Up Traefik Ingress Controller in Kubernetes Cluster

This guide will walk you through the process of setting up Traefik as the ingress controller in a Kubernetes cluster. Traefik is a popular open-source reverse proxy and load balancer that integrates seamlessly with Kubernetes.

## Prerequisites

Before proceeding with the Traefik setup, ensure that you have the following prerequisites in place:

1. A running Kubernetes cluster.
2. `kubectl` command-line tool configured to access your Kubernetes cluster.
3. Traefik resource definitions, install them (v2.10) with `kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v2.10/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml`

## Step 1: Create Namespace

First, create a Kubernetes namespace to isolate Traefik resources:

```plaintext
kubectl create namespace example-ns
```

## Step 2: Create Certificate Secret

In this tutorial, I use a origin certificate for TLS. For ACME certificates, consider checking out the traefik documentation.

From the provider of the certificate you should have the following information:
- Leaf certificate
- All intermediate certificates
- Private key

**Exception**: When using Cloudflare proxy encryption, you don't get any intermediate certificates, that's because the certificate is not signed by a global trust issuer, it is just trusted by the Cloudflare server itself. In that case the encryption to the client is handled via Cloudflare proxy certificate, you can therefor just omit the intermediate certificates and only provide the Leaf.


In the "certificate-secret.yml" file, you now have to add the leaf certificate, following the intermediate certificates (in logical order, so that the root signed one is at the end) to the *tls.crt* section. Then add the private key to the *tls.key* section.


The certificate secret is later added to the IngressRoute. You can define a custom certificate for every IngressRoute (if required).


**Pro tipp**: To troubleshoot issues with the certificate, you can use openssl to get information about the certificate (more then you get by just F5 spamming in the browser): `openssl s_client -connect test.domain.com:443 -servername test.domain.com`


Apply the secret manifest:

```plaintext
kubectl apply -f certificate-secret.yaml
```

## Step 3: Create Cluster Role and Binding

To access certain cluster resources, the traefik instances require to have some RBAC rules attached.

We attach those rules to a role which itself is attached to the service account that we use for the deployment.

Apply the cluster role and create the service account:

```plaintext
kubectl apply -f traefik-service-account.yml
```

## Step 4: Create Traefik Instances & Service

Create services to expose the Traefik controller itself.

The traefik application itself uses a deployment for the actual ingress controller and a service to expose / loadbalance them.

In the service manifest ("traefik-service.yml") you can then specify the settings for the traefik instances.

Besides that, you can choose between using an integrated Loadbalancer service (first example in "traefik-service.yml") like metallb, aws nlb, etc.
or using a NodePort (second example in "traefik-service.yml") which just exposes the service on every node, this is particularly useful when you are working with 
an external Loadbalancer which is not integrated in kubernetes.

Apply the services manifest:

```plaintext
kubectl apply -f traefik-service.yml
```

## Step 5: Create IngressRoute

Create an IngressRoute to define the routing rules ("ingress-route.yml").

Replace `test.domain.com` with your desired hostname and `example-svc` with the name of your target service.

You can create as much ingress routes as you like and change their behavior with custom matching patterns, for example
you can use something like `Host('test.domain.com') && PathPrefix('/api')` to route based on a http path.

Apply the IngressRoute manifest:

```plaintext
kubectl apply -f ingress-route.yml
```

Alternative you can also use a IngressRessource ("ingress.yml") directly from Kubernetes and link it with annotations to the controller, but it is recommended to use the Traefik IngressRoute Ressource