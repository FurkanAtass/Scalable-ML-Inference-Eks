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

helm install prometheus prometheus-community/kube-prometheus-stack

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
 aws eks update-kubeconfig --region region-code --name my-cluster

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


# TODO
add auth to endpoint
remove the single nat gateway which may prevent the pods that has pending state
maybe deploy the cluster to aws ecr
make prometheus ui reachable from outside the kubectl port-forward
make load tests more