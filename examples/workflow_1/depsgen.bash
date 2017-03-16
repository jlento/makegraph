#!/bin/bash

NBATCH=3
NJOBS=12

joblist () {
    local fmt=$1
    local batch=$2
    local b=$3
    local e=$4
    local j
    for ((j=b;j<e;j++)); do
        printf "$fmt" $batch $j
    done
}

# Goals
echo ".PHONY : all"
echo "all :$(joblist ' batch-%02d/job-%02d-output.nc' $(( NBATCH - 1 )) 0 $NJOBS)"

# NOTE: *-initial.nc files in the initial batch must NOT be make targets of any rule

# Initial batch
for ((j=0;j<NJOBS;j++)); do
    printf 'batch-%02d/job-%02d-output.nc : batch-%02d/job-%02d-initial.nc\n' 0 $j 0 $j
done

# Rest of the batches
for ((i=1;i<NBATCH;i++)); do
    for ((j=0;j<NJOBS;j++)); do
        printf 'batch-%02d/job-%02d-output.nc : batch-%02d/job-%02d-input.nc\n' $i $j $i $j
        printf 'batch-%02d/job-%02d-input.nc :%s\n' $i $j "$(joblist ' batch-%02d/job-%02d-output.nc' $((i - 1)) 0 $NJOBS)"
    done
done
