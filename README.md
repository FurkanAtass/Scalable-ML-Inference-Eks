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
      > Access policies > add access policy > add AmazonEKSAdminPolicy