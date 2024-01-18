# #!/bin/bash

# either ood_loc (ood detection) or classification (for missclassification detection)
setting=$1
split=$2

# Array of your python scripts
datasets1=("Cora" "CiteSeer" "PubMed")
datasets2=("AmazonPhotos" "AmazonComputers" "CoauthorCS" "CoauthorPhysics")

# Function to run a script on a specific GPU
run_script() {
    python3 "train_and_eval.py" with "configs/reference/${1}_gdk.yaml" \
    "run.gpu=0" "data.dataset=$3" "data.split=$4" &
}

# Max number of concurrent scripts
MAX_CONCURRENT=4

# Initialize GPU and script indices
gpu=0
script=0

# Array to keep track of running processes
pids=()

if [ "$split" == "random" ]; then
    datasets=("${datasets2[@]}")
else
    datasets=("${datasets1[@]}")
fi

# Loop through all scripts
while [ $script -lt ${#datasets[@]} ]; do
    # Run script on GPU
    run_script $setting $gpu ${datasets[$script]} $split
    pids+=($!)  # Store PID of the process
    script=$((script+1))
    gpu=$((gpu+1))

    # Reset GPU index when it reaches 4
    if [ $gpu -eq $MAX_CONCURRENT ]; then
        gpu=0
    fi

    # Wait if max concurrent scripts are running
    if [ ${#pids[@]} -eq $MAX_CONCURRENT ]; then
        wait -n  # Wait for any process to finish
        # Remove finished process from the list
        pids=($(jobs -pr))
    fi
done

# Wait for all remaining processes to finish
wait


echo "All Experiments Have Completed."