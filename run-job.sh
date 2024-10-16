#!/bin/bash

# Enhanced Logging for Debugging
set -x

# Get the job file and optional parameters
job=$1
experiment_name=$2
option=$3

# Log the parameters for verification
echo "Job file: $job"
echo "Experiment name: $experiment_name"
echo "Option: $option"

# Ensure the job file is provided and exists
if [[ -z "$job" ]]; then
  echo "Error: Job file is not specified."
  exit 1
elif [[ ! -f "$job" ]]; then
  echo "Error: Job file '$job' does not exist."
  exit 1
fi

# Create the job
if [[ -z "$experiment_name" ]]; then
  if [[ "$job" =~ pipeline.yml ]]; then
    run_id=$(az ml job create -f "$job" --query name -o tsv --set settings.force_rerun=True)
  else
    run_id=$(az ml job create -f "$job" --query name -o tsv)
  fi
else
  run_id=$(az ml job create -f "$job" --query name -o tsv --set experiment_name="$experiment_name" --set settings.force_rerun=True)
fi

# Log the run_id
echo "Run ID: $run_id"

# Check if the run ID is obtained
if [[ -z "$run_id" ]]; then
  echo "Job creation failed."
  exit 3
fi

# Option to wait or not
if [[ "$option" == "nowait" ]]; then
  az ml job show -n "$run_id" --query services.Studio.endpoint
  exit 0
fi

# Monitor the job status
status=$(az ml job show -n "$run_id" --query status -o tsv)
echo "Initial Job Status: $status"
if [[ -z "$status" ]]; then
  echo "Failed to retrieve job status."
  exit 4
fi

# Retrieve the job URI
job_uri=$(az ml job show -n "$run_id" --query services.Studio.endpoint)
echo "Job URI: $job_uri"
if [[ -z "$job_uri" ]]; then
  echo "Failed to retrieve job URI."
  exit 5
fi

# Monitor until completion
running=("Queued" "NotStarted" "Starting" "Preparing" "Running" "Finalizing")
while [[ " ${running[@]} " =~ " ${status} " ]]; do
  echo "Job Status: $status"
  sleep 8
  status=$(az ml job show -n "$run_id" --query status -o tsv)
done

# Final Status Check
if [[ "$status" == "Completed" ]]; then
  echo "Job completed successfully."
  exit 0
elif [[ "$status" == "Failed" ]]; then
  echo "Job failed."
  exit 1
else
  echo "Job not completed or failed. Status is $status"
  exit 2
fi
