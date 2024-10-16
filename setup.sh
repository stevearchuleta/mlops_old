#!/bin/bash

# Install the Azure ML extension
az extension add -n ml -y

# Verify that the Azure ML extension was installed successfully
if az extension show -n ml &>/dev/null; then
    echo "Azure ML extension installed successfully."
else
    echo "Error: Azure ML extension installation failed." >&2
    exit 1
fi

# Set default resource group, workspace, and location
GROUP="default_resource_group_test"
LOCATION="West US 2"
WORKSPACE="my_test_workspace"

# Configure defaults
az configure --defaults group=$GROUP workspace=$WORKSPACE location=$LOCATION

echo "Default resource group set to $GROUP"
