#!/bin/bash

# Number of CPU cores
NUM_CORES=$(nproc)

# Target CPU usage percentage
TARGET_USAGE=75

# Number of parallel processes needed to reach ~75% CPU
NUM_PROCESSES=$(( NUM_CORES * TARGET_USAGE / 100 ))

echo "Increasing CPU load  $TARGET_USAGE% using $NUM_PROCESSES parallel processes..."

# Start background processes for CPU load
for ((i=0; i<NUM_PROCESSES; i++)); do
    while :  # Infinite loop to keep the CPU busy
    do
        echo $(( 2**30 )) > /dev/null
    done &
done

# Keep the script running
echo "CPU load running"
wait
