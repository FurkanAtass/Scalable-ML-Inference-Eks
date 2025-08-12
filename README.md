# Scalable-Deployment


* uv sync -> update environment and activate
* uv add <package name>
* uv remove <package name>


## Docker

* docker push <user name>>/<image name>:<tagname>

## Minikube

minikube start -n 2 --memory 4400

minikube service <service-name> --url 

minikube tunnel

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  --set prometheus.service.type=LoadBalancer  

kubectl port-forward services/prometheus-kube-prometheus-prometheus 9091:9090

where 9092 is reached from localhost and 80 is the shown port for service (kubectl get svc)

avg(rate(http_request_duration_seconds_sum[2m]) / rate(http_request_duration_seconds_count[2m]))
(avg(histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[2m]))))

avg(
  rate(http_request_duration_seconds_sum[2m])
  /
  clamp_min(rate(http_request_duration_seconds_count[2m]), 1)
)

helm repo add kedacore https://kedacore.github.io/charts  
helm repo update
helm install keda kedacore/keda


## AWS CLI

https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

### Set up cli
https://docs.aws.amazon.com/eks/latest/userguide/install-awscli.html

## EKSCTL 

https://eksctl.io/installation/




## EKS

1. create IAM role
2. create cluster from console
3. create kubeconfig
aws eks update-kubeconfig --region us-east-1 --name swin-tiny-eks-cluster

 kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.17.1/deployments/static/nvidia-device-plugin.yml

4. cluster > access > IAM access entries > create access entry > enter IAM role generated
5. cluster > access > IAM access entries > click your IAM arn:aws:iam::705121141507:user/FurkanIAM 
      > Access policies > add access policy > add AmazonEKSAdminPolicy and AmazonEKSClusterAdminPolicy


## Terraform

Install terraform cli from
  https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

terraform fmt -> to chech the file formats
terraform init -> reads all the files and download the resources from terraform registry and save to files
terraform validate -> validates the files syntax etc.
terraform plan -> check what will be the impact of the execution
terraform apply -> apply the file and ask to approve
terraform destroy -> destroy all resources

terraform keeps the states for us in .tfstate file

terraform provisioners used to execute scripts, add files for yout infrastructure. their state will not handled by terraform.

For you services in terraform, check the requirements for the aws and choose the matched version for all services and their versions.

helm uninstall prometheus and delete the k8s services before terraform destroy

# TODO
remove the single nat gateway which may prevent the pods that has pending state
make prometheus ui reachable from outside the kubectl port-forward
make the access policies from terraform
terraform destroy not working

add auth to endpoint
maybe deploy the cluster to aws ecr
make load tests more
node scaling test

add the iam user name to variables
make the loadbalancers to assecible by terraform (determine loadbalancers) may only needed for CI/CD pipeline

helm repo add gpu-helm-charts \
  https://nvidia.github.io/dcgm-exporter/helm-charts

  kubectl create -f https://raw.githubusercontent.com/NVIDIA/dcgm-exporter/master/dcgm-exporter.yaml

helm install \
    dcgm-exporter \
    gpu-helm-charts/dcgm-exporter

https://docs.nvidia.com/datacenter/dcgm/latest/gpu-telemetry/dcgm-exporter.html
https://github.com/NVIDIA/dcgm-exporter 

kubectl get svc dcgm-exporter default -o yaml



# STEPS

1. cd terraform-deployment && terraform init && terraform apply

2. aws eks update-kubeconfig --region us-east-1 --name swin-tiny-eks-cluster

3. ROLE_ARN=$(terraform output -raw cluster_autoscaler_role_arn)

helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system --create-namespace \
  --set autoDiscovery.clusterName=swin-tiny-eks-cluster \
  --set awsRegion=us-east-1 \
  --set rbac.serviceAccount.create=true \
  --set rbac.serviceAccount.name=cluster-autoscaler \
  --set rbac.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="${ROLE_ARN}"

to scale down, it takes around 35 minutes

4. helm repo add nvidia https://helm.ngc.nvidia.com/nvidia \
    && helm repo update

helm install --wait --generate-name \
    -n gpu-operator --create-namespace \
    nvidia/gpu-operator \
    --version=v25.3.2

kubectl create -n gpu-operator -f ../eks-deployment/time-slicing-config-all.yaml

kubectl patch clusterpolicies.nvidia.com/cluster-policy \
    -n gpu-operator --type merge \
    -p '{"spec": {"devicePlugin": {"config": {"name": "time-slicing-config-all", "default": "any"}}}}'

It takes couple of minutes to divide the gpu.

6. helm repo add prometheus-community https://prometheus-community.github.io/helm-charts \
  && helm repo update \
  && helm install prometheus prometheus-community/kube-prometheus-stack \
  --set prometheus.service.type=LoadBalancer

7. helm repo add kedacore https://kedacore.github.io/charts \
  && helm repo update \
  && helm install keda kedacore/keda



7. cd ../eks-deployment \
  && kubectl apply -f .

---

dcgm exporter not work with time sliced gpus

gerek olmayabilir
helm repo add gpu-helm-charts https://nvidia.github.io/dcgm-exporter/helm-charts \
  && helm repo update \
  && helm install dcgm-exporter gpu-helm-charts/dcgm-exporter

  or alternatively

  kubectl apply -f https://raw.githubusercontent.com/NVIDIA/dcgm-exporter/master/dcgm-exporter.yaml

  Optional: You may check the required info for serviceMonitor by:
    kubectl get svc dcgm-exporter -o yaml
    to get port name and selectors


reach from outside
add token verification to docker image
deploy helm products to different namespaces
