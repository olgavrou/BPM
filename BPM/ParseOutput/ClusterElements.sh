#!/bin/bash

# this script takes the mcl file and a cluster id as arguments
# it returns the specific cluster

mclfile=${1}
clusterID=${2}

grep ">$clusterID " $mclfile | awk '{$1="";print $0}' > Cluster$clusterID.txt

echo "output in: Cluster$clusterID.txt"
