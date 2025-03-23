

# Function to get CPU usage
get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}'
}

# Function to get the latest created instance name
get_gcp_instance_name() {
    gcloud compute instances list --sort-by=~creationTimestamp --limit=1 --format="get(name)"
}

# Function to get external IP of the latest running GCP VM
get_gcp_external_ip() {
    INSTANCE_NAME=$(get_gcp_instance_name)
    gcloud compute instances list --filter="name=$INSTANCE_NAME" --format="get(networkInterfaces[0].accessConfigs[0].natIP)"
}

# Monitor CPU usage
CPU_USAGE=$(get_cpu_usage)
echo "CPU Usage: $CPU_USAGE%"

# Check if CPU usage exceeds 75%
if (( $(echo "$CPU_USAGE > 75" | bc -l) )); then
    echo "CPU usage exceeded 75%. Creating a new VM in GCP..."

    # Create a new VM in GCP
    INSTANCE_NAME="scaled-vm-$(date +%s)"
    gcloud compute instances create "$INSTANCE_NAME" \
        --zone=us-central1-a \
        --machine-type=n1-standard-1 \
        --image-family=ubuntu-2204-lts \
        --image-project=ubuntu-os-cloud

    # Wait for the VM to be ready
    echo "Waiting for VM to start..."
    sleep 30  # Adjust as needed

    # Get the external IP of the new VM
    EXTERNAL_IP=$(get_gcp_external_ip)

    if [ -z "$EXTERNAL_IP" ]; then
        echo "Error: Could not retrieve external IP of the GCP VM."
        exit 1
    fi

    echo "New VM External IP: $EXTERNAL_IP"

    # Create a workload script
    cat <<EOF > /tmp/workload_script.sh
#!/bin/bash
echo "Running workload on GCP VM..."
stress --cpu 4 --timeout 60  # Simulate high CPU workload for 60 seconds
EOF

    # Make the script executable
    chmod +x /tmp/workload_script.sh

    # Transfer workload script to the new VM using instance name
    gcloud compute scp /tmp/workload_script.sh ubuntu@$INSTANCE_NAME:/home/ubuntu/ --zone=us-central1-a

    # SSH into the new VM using instance name and execute the workload script
    gcloud compute ssh ubuntu@$INSTANCE_NAME --zone=us-central1-a --command "bash /home/ubuntu/workload_script.sh"
    
    echo "Workload transferred successfully!"
else
    echo "CPU usage is under control."
fi

