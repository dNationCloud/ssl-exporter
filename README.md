# dNation SSL Exporter Helmchart

This repository contains a helmchart for  [ribbybibby/ssl_exporter](https://github.com/ribbybibby/ssl_exporter).
## Dependencies
- [Helm3](https://helm.sh)
- [Kube prometheus stack ](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) - optional

## Installation

### Option 1: Install our Monitoring Stack
This chart is installed as a part of  [dNation Kubernetes Monitoring Stack](https://github.com/dNationCloud/kubernetes-monitoring-stack).
Our monitoring stack includes other monitoring tools such as Prometheus, Grafana, Loki and Thanos.

### Oprion 2: Install alongside Prometheus
- Deploy Prometheus operator [Kube prometheus stack ](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
```shell
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kube-prometheus-stack  prometheus-community/kube-prometheus-stack
```
- Deploy SSL exporter with service monitor enabled
```shell
# Add dNation helm repository
helm repo add dnationcloud https://dnationcloud.github.io/helm-hub/
helm repo update
helm install ssl-exporter dnationcloud/ssl-exporter --set serviceMonitor.enabled=true
```
### Option 3: Standalone Installation
- The chart can be installed as standalone by
```shell
# Add dNation helm repository
helm repo add dnationcloud https://dnationcloud.github.io/helm-hub/
helm repo update
helm install ssl-exporter dnationcloud/ssl-exporter
```
> NOTE: Do not use `--set serviceMonitor.enabled=true` when installing without Prometheus. The service monitor requires Prometheus to be deployed.

## Configuration
### Values
- Configure with values.yaml
```yaml
serviceMonitor:
  enabled: true
  # Automatically label with "release: {{ .Release.Name }}"
  # This label is used in dnation k8s monitoring stack
  releaseLabel: true
  extraLabels: {}
  # Metrics scrape interval
  scrapeInterval: 15s
  # Metrics scrape timeout
  scrapeTimeout: 14s
  # External URLs to scrape
  externalTargets:
  - example.com:443
  # Kubeconfig files to scrape
  kubeconfigTargets:
  - /etc/kubernetes/admin.conf
  # Internal Kubernetes certificate (glob syntax suppoted)
  fileTargets:
  - "/etc/kubernetes/pki/**/*.crt"
  # Certificates within Kubernetes secrets in <namespace>/<secret> format (glob syntax suppoted)
  secretTargets:
  # All secrets across all namespaces
  - "*/*"
```
## Usage
- To see available metrics, port-forward to ssl-exporter service
```shell
kubectl port-forward svc/<ssl-exporter-service-name> 9219:9219
```
- You can get the metrics with `curl`, e.g. the following will get all certificates from k8s secrets
```shell
curl "localhost:9219/probe?module=kubernetes&target=*/*"
```
- For more information, see ssl-exporter [README](https://github.com/ribbybibby/ssl_exporter)

- Port-forward to your instance of Prometheus to browse the metrics
```shell
kubectl port-forward svc/<your-prometheus-service> 9090:9090
```
- Get the metrics, e. g. the expiration date of kubeconfig certificate
```
ssl_kubeconfig_cert_not_after{job="ssl-kubernetes-kubeconfig"}
```
- Relevant job labels are
```
{job="ssl-external-urls"}
{job="ssl-kubernetes-kubeconfig"}
{job="ssl-kubernetes-files"}
{job="ssl-kubernetes-secrets"}
```
- For more information about metrics, see ssl-exporter [README](https://github.com/ribbybibby/ssl_exporter)
