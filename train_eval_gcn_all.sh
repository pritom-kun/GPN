# #!/bin/bash

# either ood_loc (ood detection) or classification (for missclassification detection)
setting=$1
train_eval=$2
split=$3

# Array of your python scripts
datasets1=("Cora" "CiteSeer" "PubMed")
datasets2=("AmazonPhotos" "AmazonComputers" "CoauthorCS" "CoauthorPhysics")

# Function to run a script on a specific GPU
run_script() {
    if [ "$2" == "eval" ]; then
        python3 "train_and_eval.py" with "configs/reference/${1}_gcn.yaml" \
        "run.gpu=$3" "data.dataset=$4" "data.split=$5" &
    elif [ "$5" == "random" ]; then
        python3 "train_and_eval.py" with "configs/reference/${1}_gcn.yaml" \
        "run.num_inits=10" "run.num_splits=10" "run.gpu=$3" "data.dataset=$4" "data.split=$5" &
    elif [ "$5" == "public" ]; then
        python3 "train_and_eval.py" with "configs/reference/${1}_gcn.yaml" \
        "run.num_inits=100" "run.gpu=$3" "data.dataset=$4" "data.split=$5" &
    else
        echo "Wrong or missing parameter for running the script!"
        exit 1
    fi
}

# Max number of concurrent scripts
MAX_CONCURRENT=2

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
    run_script $setting $train_eval $gpu ${datasets[$script]} $split
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