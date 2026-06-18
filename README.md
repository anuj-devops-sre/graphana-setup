# Monitoring Stack on AWS — Standalone + EKS (Helm & Operator)

A complete observability stack — **Prometheus + Grafana + Alertmanager + Node Exporter** —
demonstrated in **three deployment models**:

1. **Standalone** on a single EC2 instance (Terraform + systemd via shell script)
2. **EKS — Plain Helm** (community charts, config via `values.yaml`)
3. **EKS — Prometheus Operator** (`kube-prometheus-stack`, config via CRDs)

This shows the same stack deployed the bare-metal way and two Kubernetes-native ways.

---

## Tech Stack

| Tool          | Purpose                                  |
|---------------|------------------------------------------|
| Terraform     | Provision EC2 + Security Group           |
| AWS EC2 / EKS | Host the monitoring services             |
| Prometheus    | Metrics collection and storage           |
| Node Exporter | System-level metrics (CPU, RAM, Disk)    |
| Alertmanager  | Alert routing, grouping, Slack delivery  |
| Grafana       | Visualization and dashboards             |

---

## Architecture (Standalone)

    [ EC2 Instance ]
          |-- Prometheus    (9090)  -> scrapes Node Exporter, evaluates alert rules
          |-- Node Exporter (9100)  -> exposes system metrics
          |-- Alertmanager  (9093)  -> routes alerts to Slack
          |-- Grafana       (3000)  -> reads from Prometheus

---

## Repository Structure

    graphana-setup/
    |-- main.tf                         # EC2 + Security Group (ports 22/3000/9090/9100/9093)
    |-- variables.tf                    # Input variables
    |-- outputs.tf                      # Public IP, Grafana/Prometheus URLs
    |-- terraform.tfvars                # Your values (fill before apply)
    |
    |-- manual-setup/                   # Standalone (EC2 + systemd)
    |   |-- install.sh                  # Installs Prometheus, Node Exporter, Alertmanager, Grafana
    |   |-- prometheus.yml              # Scrape config + rule_files + alertmanager target
    |   |-- alert-rules.yml             # PromQL alert rules (down, CPU, memory, disk)
    |-- alertmanager/
    |   |-- alertmanager.yml            # Slack routing, grouping, inhibition
    |
    |-- eks-helm-setup/                 # EKS via plain community Helm charts
    |   |-- namespace.yaml
    |   |-- prometheus-values.yaml      # scrape config + rules in serverFiles -> ConfigMap
    |   |-- grafana-values.yaml         # datasource auto-link, PVC, dashboard import
    |
    |-- eks-operator-setup/             # EKS via kube-prometheus-stack (Operator)
    |   |-- namespace.yaml
    |   |-- values.yaml                 # whole stack + alertmanager routing
    |   |-- servicemonitors/            # ServiceMonitor CRD (label-based scrape discovery)
    |   |-- prometheusrules/            # PrometheusRule CRD (alert rules)
    |   |-- grafana-dashboards/         # ConfigMap with grafana_dashboard=1 (sidecar auto-load)
    |
    |-- README.md

---

## Setup 1 — Standalone (Terraform + EC2)

### Step 1 — Fill terraform.tfvars

    aws_region    = "ap-south-1"
    ami_id        = "ami-0f58b397bc5c1f2e8"
    instance_type = "t3.medium"
    key_name      = "your-key-pair-name"
    subnet_id     = "subnet-xxxxxxxxx"
    vpc_id        = "vpc-xxxxxxxxx"

### Step 2 — Provision

    terraform init
    terraform plan
    terraform apply

### Step 3 — Install services on EC2

Copy the whole repo (install.sh needs the adjacent yml files):

    scp -i your-key.pem -r manual-setup alertmanager ubuntu@<instance_public_ip>:~
    ssh -i your-key.pem ubuntu@<instance_public_ip>
    chmod +x manual-setup/install.sh
    ./manual-setup/install.sh

### Verify

    sudo systemctl status prometheus node_exporter alertmanager grafana-server

### Access

| Service       | URL                                      | Login         |
|---------------|------------------------------------------|---------------|
| Grafana       | http://<instance_public_ip>:3000         | admin / admin |
| Prometheus    | http://<instance_public_ip>:9090         | -             |
| Alertmanager  | http://<instance_public_ip>:9093         | -             |
| Node Exporter | http://<instance_public_ip>:9100/metrics | -             |

> Set your real Slack webhook in `alertmanager/alertmanager.yml` (replace `REPLACE/WITH/WEBHOOK`).

---

## Setup 2 — EKS, Plain Helm

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update

    kubectl apply -f eks-helm-setup/namespace.yaml
    helm install prometheus prometheus-community/prometheus -n monitoring -f eks-helm-setup/prometheus-values.yaml
    helm install grafana grafana/grafana -n monitoring -f eks-helm-setup/grafana-values.yaml

Scrape config and alert rules live in `serverFiles` inside `prometheus-values.yaml`,
which Helm renders into a ConfigMap mounted in the Prometheus pod. Storage uses gp3 PVC (EBS CSI).

---

## Setup 3 — EKS, Prometheus Operator

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update

    kubectl apply -f eks-operator-setup/namespace.yaml
    helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring -f eks-operator-setup/values.yaml

    kubectl apply -f eks-operator-setup/servicemonitors/
    kubectl apply -f eks-operator-setup/prometheusrules/
    kubectl apply -f eks-operator-setup/grafana-dashboards/

Scraping is defined by `ServiceMonitor` CRDs (label selectors), alerts by `PrometheusRule`
CRDs, and dashboards by ConfigMaps labelled `grafana_dashboard: "1"` (Grafana sidecar
auto-loads them). `serviceMonitorSelectorNilUsesHelmValues: false` lets custom CRDs be
picked up without matching the Helm release label.

---

## Config Mapping Across Setups

| Concern        | Standalone           | EKS Plain Helm                | EKS Operator            |
|----------------|----------------------|-------------------------------|-------------------------|
| Scrape config  | prometheus.yml       | values.yaml -> ConfigMap      | ServiceMonitor CRD      |
| Alert rules    | alert-rules.yml      | serverFiles.alerting_rules.yml| PrometheusRule CRD      |
| Alert routing  | alertmanager.yml     | values.yaml (alertmanager)    | values.yaml (alertmanager) |
| Storage        | EBS (manual mount)   | gp3 PVC (EBS CSI)             | gp3 PVC (EBS CSI)       |
| Discovery      | static targets       | Kubernetes SD                 | label-based auto         |

---

## Cleanup

    terraform destroy                                  # standalone
    helm uninstall prometheus grafana -n monitoring    # eks plain helm
    helm uninstall kube-prometheus-stack -n monitoring # eks operator

---

## Author

Anuj — DevOps and SRE Engineer
Working with AWS, Kubernetes, Terraform, and observability stacks in production.

GitHub: https://github.com/anuj-devops-sre
