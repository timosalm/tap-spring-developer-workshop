#!/bin/bash 
if [ -f "config/workload.yaml" ]; then
    exit 1
fi
exit 0