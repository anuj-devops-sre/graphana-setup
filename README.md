# Grafana Monitoring Stack Setup on AWS EC2

A complete observability stack setup — Grafana + Prometheus + Node Exporter — on AWS EC2 using Terraform (Infrastructure as Code) and a manual shell script method.

This project is useful for DevOps engineers who want to quickly spin up a monitoring stack on AWS without Kubernetes.

---

## Tech Stack

| Tool          | Purpose                               |
|---------------|---------------------------------------|
| Terraform     | Provision EC2 + Security Group        |
| AWS EC2       | Host all monitoring services          |
| Prometheus    | Metrics collection and storage        |
| Node Exporter | System-level metrics (CPU, RAM, Disk) |
| Grafana       | Visualization and Dashboards          |

---

## Architecture

    [ EC2 Instance ]
          |
          |-- Prometheus    (port 9090)  <-- scrapes Node Exporter
          |-- Node Exporter (port 9100)  <-- exposes system metrics
          |-- Grafana       (port 3000)  <-- reads from Prometheus

---

## Project Structure

    graphana-setup/
    |-- main.tf                  # EC2 + Security Group
    |-- variables.tf             # All input variables
    |-- outputs.tf               # Public IP, URLs
    |-- terraform.tfvars         # Your actual values (fill before apply)
    |-- manual-setup/
    |   |-- install.sh           # Shell script to install all tools
    |-- README.md

---

## Pre-requisites

- AWS CLI installed and configured (aws configure)
- Terraform installed (>= 1.0)
- An existing AWS account with:
  - VPC ID
  - Public Subnet ID
  - EC2 Key Pair created in AWS
- SSH client available

---

## Method 1 — Terraform (Recommended)

### Step 1 — Fill terraform.tfvars

    aws_region    = "ap-south-1"
    ami_id        = "ami-0f58b397bc5c1f2e8"
    instance_type = "t3.medium"
    key_name      = "your-key-pair-name"
    subnet_id     = "subnet-xxxxxxxxx"
    vpc_id        = "vpc-xxxxxxxxx"

### Step 2 — Init and Apply

    terraform init
    terraform plan
    terraform apply

Note the instance_public_ip from output.

### Step 3 — SSH into EC2

    ssh -i /path/to/your-key.pem ubuntu@<instance_public_ip>

### Step 4 — Copy and Run install.sh

    # From your local machine
    scp -i /path/to/your-key.pem manual-setup/install.sh ubuntu@<instance_public_ip>:~

    # Inside EC2
    chmod +x install.sh
    ./install.sh

---

## Method 2 — Manual (Without Terraform)

Spin up any Ubuntu 22.04 EC2 manually from AWS Console, open ports 22, 3000, 9090, 9100 in Security Group, then:

    scp -i /path/to/your-key.pem manual-setup/install.sh ubuntu@<instance_public_ip>:~
    ssh -i /path/to/your-key.pem ubuntu@<instance_public_ip>
    chmod +x install.sh
    ./install.sh

---

## Verify Services on EC2

    sudo systemctl status prometheus
    sudo systemctl status node_exporter
    sudo systemctl status grafana-server

All 3 should show: active (running)

---

## Access in Browser

| Service       | URL                                        | Default Login |
|---------------|--------------------------------------------|---------------|
| Grafana       | http://<instance_public_ip>:3000           | admin / admin |
| Prometheus    | http://<instance_public_ip>:9090           | -             |
| Node Exporter | http://<instance_public_ip>:9100/metrics   | -             |

---

## Add Prometheus as Datasource in Grafana

1. Login to Grafana
2. Go to: Configuration > Data Sources > Add data source
3. Select: Prometheus
4. URL: http://localhost:9090
5. Click: Save and Test

---

## Cleanup

    terraform destroy

---

## Author

Anuj — DevOps and SRE Engineer
Working with AWS, Kubernetes, Terraform, and Observability stacks in production.

GitHub: https://github.com/anuj-devops-sre

