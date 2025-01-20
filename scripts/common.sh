#!/bin/bash

TERRAFORM="tofu"

check_do_token() {
    echo "Checking DO_TOKEN environment variable..."
    if [ -z "$DO_TOKEN" ]; then
        echo "Error: DO_TOKEN environment variable is not set"
        echo "Usage: DO_TOKEN=your_token ./script.sh"
        exit 1
    fi
    # Export DO_TOKEN as a tofu variable
    export TF_VAR_do_token="$DO_TOKEN"
}
