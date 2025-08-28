# Scalable-ML-Inference-Eks

This project aims to deploy a machine learning model fully scalable such that it can both scale pods and nodes according to the custom metrics. It is not going to details of creating a docker image but there are some tips about it.

Before starting to the project, we need a docker image to orchestrate.
Not to spend to much time, I choose a visual transformer image classification model Swin Tiny. which has a small inference time and also a big model (~300MB) compared to other image classification models. which is a good challenge for orchestration.

In the app folder you can see that I used the "uv" as a package manager which is faster and more efficient than other python package managers. 

You may install it via the link https://docs.astral.sh/uv/getting-started/installation/
Some tips to use uv
* uv sync -> update environment and activate
* uv add <package name>
* uv remove <package name>


## Docker
You can find the app code and Dockerfile in app directory. I used nvidia based image to run the model on GPU.
There are some commands to reduce the docker image size as:

apt-get clean && \
rm -rf /var/lib/apt/lists/*

then you may push you image to a container registery such as docker hub, ECR etc. For dockerhub, you should login the docker via terminal as:
* docker login
and write your username and password. 
After login, push your image to docker hub.
* docker push <user name>>/<image name>:<tagname>
You can use this image inside of the kubernetes/deployment.yaml as containers > image


Before proceeding, you should install the awscli, terraform and set up an IAM role (from your AWS account.)
## AWS CLI

https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

### Set up cli
https://docs.aws.amazon.com/eks/latest/userguide/install-awscli.html

## EKS

1. create IAM role with admin access
* from aws console, write IAM on the search bar and go to the IAM service
* Click users 
* on the top right, click create user
* give a name, not needed to console access, go next
* from permission options select attach policies directly. 
* write admin to the opened search bar and select AdministratorAccess 
* go next and create user

2. Create access key
* From user section, click the created user
* click security credentials and go down to access keys
* click create access key
* select command line interface (CLI) and go next 
* you get access key and secret access key. You can download it as csv

after that, run aws login and use these credentatials

## Terraform

Install terraform cli from
  https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

Some commands to use terraform

terraform fmt -> to chech the file formats and do necessary fomatting
terraform init -> reads all the files and download the resources from terraform registry and save to files
terraform validate -> validates the files syntax etc.
terraform plan -> check what will be the impact of the execution
terraform apply -> apply the file and ask to approve
terraform destroy -> destroy all resources

terraform keeps the states for us in .tfstate file

terraform provisioners used to execute scripts, add files for yout infrastructure. their state will not handled by terraform.

For you services in terraform, check the requirements for the aws and choose the matched version for all services and their versions.

helm uninstall prometheus and delete the k8s services before terraform destroy



# STEPS

1. cd terraform && terraform init && terraform apply

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

cd ../kubernetes

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


7. kubectl apply -f .

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

# TODO

reach from outside
add token verification to docker image
deploy helm products to different namespaces
remove the single nat gateway which may prevent the pods that has pending state

maybe deploy the cluster to aws ecr