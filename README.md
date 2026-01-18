# 🛡️ Project Sentinel

**Automated Kubernetes Governance Platform**

A real-world GitOps pipeline built to automate infrastructure deployments and enforce cloud cost policies because nobody wants a surprise $500 DigitalOcean bill at the end of the month.

---

## What This Does

Sentinel deploys a Kubernetes cluster on DigitalOcean and sets up automated governance using ArgoCD and Kyverno. Instead of manually applying manifests and hoping nothing breaks, everything runs through a Git-based workflow with built-in policy enforcement.

The main problem it solves: **stopping expensive LoadBalancer services from being created accidentally**. When you're running on student credits or a tight budget, one wrong `kubectl apply` can cost you weeks of cloud budget.

---

## Tech Stack

- **Terraform** - Infrastructure provisioning
- **Kubernetes** - Container orchestration (1.32.1)
- **ArgoCD** - GitOps continuous delivery
- **Kyverno** - Policy-as-Code admission controller
- **DigitalOcean** - Cloud provider (Bangalore region)
- **Helm** - Package management
- **YAML/HCL** - Configuration languages

---

## Architecture
```
┌─────────────────┐
│   Git Repo      │  ← You push here
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    ArgoCD       │  ← Watches for changes
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Kyverno       │  ← Validates policies
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  K8s Cluster    │  ← Deploys if valid
└─────────────────┘
```

**How it works:**
1. Push a deployment to the `apps/` folder
2. ArgoCD detects the change and tries to apply it
3. Kyverno admission controller checks if it violates any policies
4. If it passes (e.g., uses ClusterIP instead of LoadBalancer), it deploys
5. If it fails, deployment is rejected with a clear error message

---

## Setup

### Prerequisites

- DigitalOcean account with API token
- `terraform` installed
- `kubectl` installed  
- `helm` installed

### 1. Clone the Repo

```bash
git clone https://github.com/vaibhav-2703/sentinel.git
cd sentinel
```

### 2. Set Your DigitalOcean Token

```bash
export DIGITALOCEAN_TOKEN="your_token_here"
```

### 3. Provision the Cluster

```bash
terraform init
terraform plan
terraform apply
```

This creates a single-node Kubernetes cluster in Bangalore (`blr1`) with 1 vCPU and 2GB RAM.

### 4. Connect to the Cluster

```bash
# Get the kubeconfig
doctl kubernetes cluster kubeconfig save sentinel-cluster

# Verify connection
kubectl get nodes
```

### 5. Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get the admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 6. Install Kyverno

```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm install kyverno kyverno/kyverno -n kyverno --create-namespace
```

### 7. Apply the Policies

```bash
kubectl apply -f policies/block-lb.yaml
```

### 8. Deploy the ArgoCD Application

```bash
kubectl apply -f argo-app.yaml
```

Now ArgoCD is watching the `apps/` folder. Any changes you push will be automatically deployed.

---

## Testing the Policy Enforcement

### ✅ This Works (ClusterIP)

```bash
kubectl apply -f apps/deployment.yaml
```

Output: `deployment.apps/demo-app created`

### ❌ This Fails (LoadBalancer)

```bash
kubectl apply -f policies/bad-service.yaml
```

Output:  
```
Error from server: error when creating "policies/bad-service.yaml": 
admission webhook "validate.kyverno.svc-fail" denied the request: 

🛑 ACCESS DENIED: LoadBalancers cost money! Use ClusterIP instead.
```

---

## Real Issues I Hit (and Fixed)

### OOM Errors During Scaling

When I tried installing Prometheus alongside ArgoCD and Kyverno, the 2GB node ran out of memory. Had to:
- Add resource limits to deployments
- Use `kubectl top nodes` and `kubectl top pods` to monitor usage
- Temporarily scaled down replicas to 1

**Lesson:** Always set resource requests/limits, especially on small nodes.

### ArgoCD Not Syncing

ArgoCD was installed but wouldn't auto-sync my changes. Turns out I forgot to set `syncPolicy.automated` in the Application manifest. Once I added `prune: true` and `selfHeal: true`, it worked perfectly.

### Kyverno Policy Not Blocking

Initially used `validationFailureAction: Audit` instead of `Enforce`. This meant violations were logged but not blocked. Switched to `Enforce` mode to actually prevent bad deployments.

---

## Project Structure

```
sentinel/
├── main.tf                 # Kubernetes cluster definition
├── provider.tf             # Terraform provider config
├── argo-app.yaml          # ArgoCD application manifest
├── apps/
│   └── deployment.yaml    # Sample nginx deployment
└── policies/
    ├── block-lb.yaml      # Kyverno policy (enforced)
    └── bad-service.yaml   # Test file (should fail)
```

---

## Future Improvements

- [ ] Add Prometheus + Grafana for monitoring
- [ ] Implement cert-manager for automatic TLS
- [ ] Set up GitHub Actions for automated testing
- [ ] Add Horizontal Pod Autoscaler (HPA)
- [ ] Create a proper microservices demo app instead of nginx
- [ ] Add ingress controller for external access
- [ ] Integrate Trivy for container image scanning

---

## Why I Built This

I wanted to understand how real DevOps teams prevent misconfigurations in production. Reading about Policy-as-Code is one thing, but actually getting blocked by your own policy and debugging it taught me way more.

Also, I blew through $15 of DigitalOcean credits in a weekend because I left a LoadBalancer running. Kyverno makes sure that never happens again.

---

## Cleanup

When you're done testing:

```bash
terraform destroy
```

This deletes the entire cluster and stops all billing.

---

## Connect

Built by [Vaibhav Chouhan](https://github.com/vaibhav-2703)  
Questions? Open an issue or reach out!
