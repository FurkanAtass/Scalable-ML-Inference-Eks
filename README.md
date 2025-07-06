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
