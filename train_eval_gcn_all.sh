# #!/bin/bash

# either ood_loc (ood detection) or classification (for missclassification detection)
setting=$1
train_eval=$2

# Array of your python scripts
datasets=("Cora" "CiteSeer" "PubMed" "AmazonPhotos" "AmazonComputers" "CoauthorCS" "CoauthorPhysics")
splits=("public" "public" "public" "random" "random" "random" "random")

ood_left_out_classes=("[4,5,6]" "[4,5]" "[2]" "[5,6,7]" "[5,6,7,8,9]" "[11,12,13,14]" "[3,4]")
# ood_left_out_classes=("[0,1,2]" "[0,1]" "[0]" "[0,1,2]" "[0,1,2,3,4]" "[0,1,2,3]" "[0,1]")
# ood_left_out_classes=("[0,2,4]" "[1,2]" "[1]" "[3,4,5]" "[2,3,4,5,7]" "[1,2,9,12]" "[2,3]")
# ood_left_out_classes=("[1,3,5]" "[3,4]" "[2]" "[1,4,6]" "[1,2,3,6,7]" "[3,6,10,13]" "[0,4]")
# ood_left_out_classes=("[3,4,5]" "[0,5]" "[2]" "[2,3,7]" "[2,4,5,8,9]" "[2,3,6,10]" "[1,2]")

# Function to run a script on a specific GPU
run_script() {
    if [ "$2" == "eval" ]; then
        python3 "train_and_eval.py" with "configs/reference/${1}_gcn.yaml" \
        "run.gpu=$3" "data.dataset=$4" "data.split=$5" "data.ood_left_out_classes=$6" &
    elif [ "$5" == "random" ]; then
        python3 "train_and_eval.py" with "configs/reference/${1}_gcn.yaml" \
        "run.num_inits=10" "run.num_splits=10" "run.gpu=$3" "data.dataset=$4" "data.split=$5" "data.ood_left_out_classes=$6" &
    elif [ "$5" == "public" ]; then
        python3 "train_and_eval.py" with "configs/reference/${1}_gcn.yaml" \
        "run.num_inits=100" "run.gpu=$3" "data.dataset=$4" "data.split=$5" "data.ood_left_out_classes=$6" &
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

# Loop through all scripts
while [ $script -lt ${#datasets[@]} ]; do
    # Run script on GPU
    run_script $setting $train_eval $gpu ${datasets[$script]} ${splits[$script]} ${ood_left_out_classes[$script]}
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