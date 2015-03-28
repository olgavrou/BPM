#!/bin/bash

#-- GetClusters.sh ------------------------------------------------------------
# 
# This script returns the clusters (their ids) that contain a specific
# protein or genome
# 
# Arguments: 
# 1. The protein or geneome Identifier
# 2. The mcl file that contains all the clusters
#
# Output: <ID>_clusters.txt
#
#------------------------------------------------------------------------------


ID=${1}
mclfile=${2}

grep "$ID" $mclfile | awk '{print $1}' | cut -d">" -f2 > "$ID"_clusters.txt

echo "Output in "$ID"_clusters.txt"
