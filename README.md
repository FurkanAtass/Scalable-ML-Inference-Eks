## Scalable ML Inference on EKS (GPU + KEDA + Prometheus)

This repository provisions an AWS EKS cluster with GPU nodes and deploys a FastAPI inference service running a Swin-Tiny image classification model. It enables horizontal scaling based on custom Prometheus metrics via KEDA and supports GPU time-slicing using NVIDIA GPU Operator to scale nodes.

### Key Features
- **GPU-backed inference**: PyTorch `swin_t` model served with FastAPI/Uvicorn
- **Autoscaling**: KEDA scales pods using custom latency metric from Prometheus
- **Node autoscaling**: Cluster Autoscaler scales GPU nodes
- **Observability**: `/metrics` endpoint scraped by Prometheus and ServiceMonitor
- **GPU sharing**: Optional time-slicing to run multiple pods per GPU

---

## Architecture Overview
- Terraform creates VPC, EKS (managed node group with `g4dn.xlarge`), and security rules.
- Helm installs NVIDIA GPU Operator, Prometheus Stack, KEDA, and Cluster Autoscaler.
- Kubernetes manifests deploy the app `Deployment`, `Service` (LoadBalancer), `ServiceMonitor`, and KEDA `ScaledObject`.

---

## Prerequisites
- AWS account and credentials configured (Administrator or equivalent)
- macOS/Linux shell with the following installed:
  - `aws` CLI
  - `terraform`
  - `kubectl`
  - `helm`
  - Docker and a container registry account (Docker Hub or ECR)
- GPU quota in the chosen region (defaults to `us-east-1`) for `g4dn.xlarge`

---

## Repository Structure
- `app/`: FastAPI app, `Dockerfile`, `pyproject.toml`, `run.sh`, test client
- `kubernetes/`: Deployment, Service, ServiceMonitor, KEDA ScaledObject, time-slicing config
- `terraform/`: VPC, EKS, IRSA for Cluster Autoscaler, security groups, outputs

---

## Build and Push the Inference Image
The app code and `Dockerfile` are in `app/`. The image uses `uv` to install Python deps and runs `uvicorn`.

```bash
cd app
# Build
docker build -t <registry>/<repo>:<tag> .

# Login and push (Docker Hub example)
docker login
docker push <registry>/<repo>:<tag>
```

Update the image reference in `kubernetes/deployment.yaml` under `spec.template.spec.containers[0].image`.

---

## Provision EKS with Terraform
```bash
cd terraform
terraform init
terraform apply

# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name swin-tiny-eks-cluster
```
Outputs include the IAM role ARN for Cluster Autoscaler IRSA.

---

## Install Cluster Autoscaler (IRSA)
```bash
# Capture the IRSA role ARN created by Terraform
ROLE_ARN=$(terraform output -raw cluster_autoscaler_role_arn)

# Add autoscaler repo and install
helm repo add autoscaler https://kubernetes.github.io/autoscaler && helm repo update
helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system --create-namespace \
  --set autoDiscovery.clusterName=swin-tiny-eks-cluster \
  --set awsRegion=us-east-1 \
  --set rbac.serviceAccount.create=true \
  --set rbac.serviceAccount.name=cluster-autoscaler \
  --set rbac.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="${ROLE_ARN}"
```
Note: Scale-down decisions may take ~30 minutes.

---

## Install NVIDIA GPU Operator
```bash
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia && helm repo update
helm install --wait --generate-name \
  -n gpu-operator --create-namespace \
  nvidia/gpu-operator \
  --version=v25.3.2
```

### Optional: Enable GPU Time-Slicing
This lets multiple pods share a single GPU.
```bash
# Apply time-slicing config map
kubectl apply -f kubernetes/time-slicing-config-all.yaml -n gpu-operator

# Patch cluster policy to use it
kubectl patch clusterpolicies.nvidia.com/cluster-policy \
  -n gpu-operator --type merge \
  -p '{"spec": {"devicePlugin": {"config": {"name": "time-slicing-config-all", "default": "any"}}}}'
```
It may take a few minutes for the configuration to take effect.

---

## Install Prometheus Stack
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts && helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack \
  --set prometheus.service.type=LoadBalancer
```
`kubernetes/serviceMonitor.yaml` is configured to let Prometheus scrape the app’s `/metrics` endpoint.

---

## Install KEDA
```bash
helm repo add kedacore https://kedacore.github.io/charts && helm repo update
helm install keda kedacore/keda
```

---

## Deploy the Application Manifests
```bash
cd ..
kubectl apply -f kubernetes/
```
This applies the `Deployment`, `Service` (type `LoadBalancer` on port 8000), `ServiceMonitor`, and `ScaledObject`.

---

## Application API
- `POST /predict`: multipart file upload under form-key `file`; returns predicted class
- `GET /metrics`: Prometheus metrics
- `GET /health`: health check

Example request with `curl`:
```bash
curl -X POST \
  -F "file=@/path/to/image.jpg" \
  http://<APP_LOADBALANCER_DNS>:8000/predict
```

---

## Autoscaling with KEDA
The `ScaledObject` (`kubernetes/keda-scaledobject.yaml`) evaluates average request duration over a 2-minute window and scales pods between 1 and 100 replicas.

PromQL used:
```promql
avg(
  rate(http_request_duration_seconds_sum[2m])
  /
  clamp_min(rate(http_request_duration_seconds_count[2m]), 1)
)
```
Threshold (default): `0.020` seconds. Adjust `threshold`, `minReplicaCount`, and `maxReplicaCount` as needed.

---

## Pod placement (packing)
Pack replicas onto the same node so nodes can drain and scale down faster when load drops, while keeping latency steady. Use a strong preferred `podAffinity` (keep it preferred, not required) to co-locate replicas on the same hostname.

```yaml
affinity:
  podAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        topologyKey: kubernetes.io/hostname
        labelSelector:
          matchLabels:
            app: swin-tiny-app
```

---

## Load Testing (Optional)
A simple async load test script is provided at `app/test.py`.
```bash
# Edit API_URL in app/test.py to your app LoadBalancer DNS
uv run python app/test.py 50 5   # 50 concurrent requests, 5 rounds
```

---

## Configuration
- Region/cluster/VPC names can be adjusted in `terraform/variables.tf`
- Node group instance type in `terraform/eks.tf` (`g4dn.xlarge` by default)
- App image in `kubernetes/deployment.yaml`
- Service type and ports in `kubernetes/service.yaml`
- Prometheus access: Terraform opens 9090 to the world by default in `terraform/security_group_rules.tf` (tighten for production)

---

## Cleanup
```bash
# Remove Helm releases (optional order)
helm uninstall keda
helm uninstall prometheus
helm -n gpu-operator uninstall <gpu-operator-release-name>
helm -n kube-system uninstall cluster-autoscaler

# Delete k8s app resources
kubectl delete -f kubernetes/

# Destroy infrastructure
cd terraform
terraform destroy
```

---

## Troubleshooting
- Pods stuck Pending: ensure GPU operator is installed and nodes are GPU-capable; check `nvidia.com/gpu` resource requests.
- Prometheus not scraping app: confirm `ServiceMonitor` `release` label matches your Prometheus release name (`prometheus`) and `Service` labels/ports match the monitor selector.
- Scaling not triggered: verify Prometheus query results in the Prometheus UI and that KEDA has access to the Prometheus service address configured in `ScaledObject`.
- Slow scale-down: Kubernetes HPA/KEDA stabilization windows and Cluster Autoscaler timings can delay downscaling.