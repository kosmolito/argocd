# ArgoCD

## Argocd deployment with kustomize

```bash
# Create namespace
kubectl create ns argocd
````

```bash
# Deploy argocd
kubectl apply --server-side --force-conflicts -k bootstrap/base
```

```bash
# Check that all pods are running
kubectl -n argocd get pods
```

```bash
# Wait for argocd server to be ready
kubectl -n argocd wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server --timeout=180s
```

```bash
# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

```bash
# Port forward argocd server
kubectl -n argocd port-forward svc/argocd-server 8080:80
```
