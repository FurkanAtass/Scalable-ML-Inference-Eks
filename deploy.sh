kubectl apply -f deployment/deployment.yaml
kubectl apply -f deployment/service.yaml

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack

minikube tunnel &
kubectl port-forward services/prometheus-kube-prometheus-prometheus 9090:9090 &

kubectl apply -f deployment/serviceMonitor.yaml