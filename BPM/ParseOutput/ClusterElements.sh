#!/bin/bash

#-- ClusterElements.sh-----------------------------------------------
# 
# This script returns a specific cluster with its elements
#
# Arguments:
# 1. mcl file with all the clusters
# 2. a cluster id
#
# Output:  Cluster<clusterID>.txt
# 
#--------------------------------------------------------------------

mclfile=${1}
clusterID=${2}

grep ">$clusterID " $mclfile | awk '{$1="";print $0}' > Cluster$clusterID.txt

echo "output in: Cluster$clusterID.txt"
