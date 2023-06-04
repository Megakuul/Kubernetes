# Setting Up Traefik Ingress Controller in Kubernetes Cluster

This guide will walk you through the process of setting up Traefik as the ingress controller in a Kubernetes cluster. Traefik is a popular open-source reverse proxy and load balancer that integrates seamlessly with Kubernetes.

## Prerequisites

Before proceeding with the Traefik setup, ensure that you have the following prerequisites in place:

1. A running Kubernetes cluster.
2. `kubectl` command-line tool configured to access your Kubernetes cluster.
3. A valid SSL certificate and its corresponding private key. Replace `tls.crt` and `tls.key` in the `certificate-secret` section with your certificate and key, respectively.

## Step 1: Create Namespace

First, create a Kubernetes namespace to isolate Traefik resources:

```plaintext
kubectl create namespace example-ns
```

## Step 2: Create Certificate Secret

Create a secret to store your SSL certificate and private key:

```plaintext
apiVersion: v1
kind: Secret
metadata:
  name: certificate-secret
  namespace: example-ns
type: Opaque
data:
  tls.crt: <Base64-encoded certificate content>
  tls.key: <Base64-encoded private key content>
```

Replace `<Base64-encoded certificate content>` and `<Base64-encoded private key content>` with the respective Base64-encoded contents of your certificate and key.

Apply the secret manifest:

```plaintext
kubectl apply -f certificate-secret.yaml
```

## Step 3: Create Traefik Service Account

Create a service account for Traefik:

```plaintext
apiVersion: v1
kind: ServiceAccount
metadata:
  name: traefik-account
  namespace: example-ns
```

Apply the service account manifest:

```plaintext
kubectl apply -f traefik-service-account.yaml
```

## Step 4: Create Cluster Role and Binding

Create a cluster role and bind it to the Traefik service account:

```plaintext
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: traefik-role
  namespace: example-ns
rules:
  - apiGroups:
      - ""
    resources:
      - services
      - endpoints
      - secrets
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - extensions
      - networking.k8s.io
    resources:
      - ingresses
      - ingressclasses
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - extensions
      - networking.k8s.io
    resources:
      - ingresses/status
    verbs:
      - update
  - apiGroups:
      - traefik.containo.us
      - traefik.io
    resources:
      - ingressroutes
      - ingressroutetcps
      - ingressrouteudps
      - middlewares
      - middlewaretcps
      - serverstransports
      - tlsoptions
      - tlsstores
      - traefikservices
    verbs:
      - get
      - list
      - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: traefik-role-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: traefik-role
subjects:
  - kind: ServiceAccount
    name: traefik-account
    namespace: example-ns
```

Apply the cluster role and binding manifest:

```plaintext
kubectl apply -f traefik-cluster-role.yaml
```

## Step 5: Create Traefik Deployment

Create a deployment for the Traefik controller:

```plaintext
kind: Deployment
apiVersion: apps/v1
metadata:
  name: traefik-deployment
  namespace: example-ns
  labels:
    app: traefik
spec:
  replicas: 1
  selector:
    matchLabels:
      app: traefik
  template:
    metadata:
      labels:
        app: traefik
    spec:
      serviceAccountName: traefik-account
      containers:
        - name: traefik
          image: traefik:latest
          resources:
            limits:
              memory: "256Mi"
              cpu: "500m"
          args:
            - --api.insecure
            - --providers.kubernetesingress
            - --entrypoints.web.address=:80
            - --entrypoints.websecure.address=:443
            - --entrypoints.websecure.http.tls
            - --log.level=debug
            - --providers.kubernetescrd
            - --providers.kubernetescrd.namespaces=example-ns
          ports:
            - name: web
              containerPort: 80
            - name: websecure
              containerPort: 443
            - name: dashboard
              containerPort: 8080
```

Apply the deployment manifest:

```plaintext
kubectl apply -f traefik-deployment.yaml
```

## Step 6: Create Traefik Services

Create services to expose the Traefik controller and dashboard:

In the example Code the Loadbalancers are getting directly exposed with a Metallb, you can also do this with e.g. a NodePort or something else

```plaintext
apiVersion: v1
kind: Service
metadata:
  name: traefik-web-service
  namespace: example-ns
spec:
  type: LoadBalancer
  ports:
    - name: web
      targetPort: web
      port: 80
    - name: websecure
      targetPort: websecure
      port: 443
  selector:
    app: traefik
---
apiVersion: v1
kind: Service
metadata:
  name: traefik-dashboard-service
  namespace: example-ns
spec:
  type: LoadBalancer
  ports:
    - port: 8080
      targetPort: dashboard
  selector:
    app: traefik
```

Apply the services manifest:

```plaintext
kubectl apply -f traefik-services.yaml
```

## Step 7: Create IngressRoute

Create an IngressRoute to define the routing rules:

```plaintext
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: ingress-route
  namespace: example-ns
spec:
  entryPoints:
    - websecure
  routes:
    - kind: Rule
      match: Host(`test.domain.com`)
      services:
        - name: example-svc
          port: 80
  tls:
    secretName: certificate-secret
```

Replace `test.domain.com` with your desired hostname and `example-svc` with the name of your target service.

Apply the IngressRoute manifest:

```plaintext
kubectl apply -f ingress-route.yaml
```

Alternative you can also use a IngressRessource directly from Kubernetes and link it with annotations to the controller, but it is recommended to use the Traefik IngressRoute Ressource