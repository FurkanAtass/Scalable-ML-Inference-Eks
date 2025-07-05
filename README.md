# Scalable-Deployment


* uv sync -> update environment and activate
* uv add <package name>
* uv remove <package name>


## Docker

* docker push <user name>>/<image name>:<tagname>

minikube start -n 2 --memory 4400

minikube service <service-name> --url 

minikube tunnel

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

helm repo update

kubectl port-forward services/prometheus-server 9092:80

where 9092 is reached from localhost and 80 is the shown port for service (kubectl get svc)
