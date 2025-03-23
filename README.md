# Automated Scaling and Resource Migration: From Local VM to Google Cloud Platform (GCP)

This guide provides a step-by-step process to set up an automated system that monitors CPU usage on a local virtual machine (VM) and migrates workloads to Google Cloud Platform (GCP) when the CPU usage exceeds 75%. The system ensures seamless scaling and resource management without manual intervention.

## Table of Contents
1. [Setting Up Your Local VM](#1-setting-up-your-local-vm)
2. [Monitoring CPU Usage](#2-monitoring-cpu-usage)
3. [Setting Up GCP](#3-setting-up-gcp)
4. [Migrating Workload to GCP](#4-migrating-workload-to-gcp)
5. [Testing with a Sample Application](#5-testing-with-a-sample-application)
6. [Conclusion](#6-conclusion)

---

## 1. Setting Up Your Local VM

To begin, you need a local VM that acts as your on-premises server. Follow these steps:

- **Choose a Virtualization Tool**: Install VirtualBox or any other virtualization software.
- **Create the VM**: Set up a new VM using Ubuntu 22.04 LTS as the operating system. Allocate sufficient resources:
  - 2 CPUs
  - 4GB of RAM
  - 10GB of disk space

---

## 2. Monitoring CPU Usage

To ensure your VM doesn't get overloaded, monitor its CPU usage. If the CPU usage exceeds 75%, the system will trigger the migration process.

- **Bash Script for CPU Monitoring**:
  Use the following script to check CPU usage. The `top` command provides real-time system performance data, and the script calculates the CPU usage by subtracting the idle percentage from 100.

  ```bash
  CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
  echo "CPU Usage: $CPU_USAGE%"
  ```

  This script will help detect when the CPU is overburdened.

---

## 3. Setting Up GCP

To automate the creation of a new VM in GCP when the local VM's CPU usage exceeds 75%, follow these steps:

- **Install Google Cloud SDK**: Download and install the Google Cloud SDK on your local machine.
- **Create a GCP Project**: Set up a new project in GCP and assign the necessary permissions.
- **Activate Service Account**: Obtain and activate the service account key for your GCP project.

- **Automate VM Creation**:
  Use the `gcloud` command-line tool to create a new VM in GCP when the CPU usage exceeds 75%.

  ```bash
  if (( $(echo "$CPU_USAGE > 75" | bc -l) )); then
    echo "CPU usage exceeded 75%. Creating a new VM in GCP..."
    gcloud compute instances create scaled-vm-$(date +%s) \
      --zone=us-central1-a \
      --machine-type=n1-standard-1 \
      --image-family=ubuntu-2204-lts \
      --image-project=ubuntu-os-cloud
  fi
  ```

---

## 4. Migrating Workload to GCP

Once the GCP VM is created, transfer the workload to the new VM:

- **Retrieve the External IP**:
  Use the following command to get the external IP address of the newly created GCP VM:

  ```bash
  EXTERNAL_IP=$(gcloud compute instances list --format='get(EXTERNAL_IP)' --filter="name=(scaled-vm-*)")
  echo "New GCP VM External IP: $EXTERNAL_IP"
  ```

- **Transfer and Run the Workload**:
  Transfer the workload script to the GCP VM and execute it remotely:

  ```bash
  if [ -n "$EXTERNAL_IP" ]; then
    echo "Transferring workload to GCP VM..."
    gcloud compute scp /tmp/workload_script.sh ubuntu@$EXTERNAL_IP:/home/ubuntu/
    gcloud compute ssh ubuntu@$EXTERNAL_IP --command "chmod +x /home/ubuntu/workload_script.sh && /home/ubuntu/workload_script.sh &"
  fi
  ```

---

## 5. Testing with a Sample Application

To test the system, create a sample workload script that simulates CPU activity or serves a webpage.

- **Workload Script**:
  Create a script named `/tmp/workload_script.sh` on your local machine:

  ```bash
  #!/bin/bash
  echo "Starting workload on GCP VM..."
  while true; do echo "Working hard!" && sleep 1; done  # Simulates CPU activity
  ```

- **Verify the Script is Running**:
  Use the following command to check if the script is running on the GCP VM:

  ```bash
  gcloud compute ssh ubuntu@$EXTERNAL_IP --command "ps aux | grep workload_script.sh"
  ```

  You can also add logging to track the progress of the workload.

---

## 6. Conclusion

This setup ensures that when your local VM becomes overloaded (CPU usage > 75%), a new VM is automatically created in GCP, and the workload is seamlessly transferred. This automated system acts as a smart assistant, scaling resources without requiring manual intervention.

---
