#!/bin/bash

#-- ClustersWithNumElements.sh ----------------------------------------------------------
#
# This script returns the clusters (their ids) that have a specfic number of elements 
#
# Arguments:
# 1. The mcl file that contains all the clusters
# 2. The number of elements to look for
#
# Output: Clusters<numberofelements>Elements.txt
#
#----------------------------------------------------------------------------------------

mclfile=${1}
numberofelements=${2}

awk '{if(NF=='$((numberofelements + 1))'){print $1}}' $mclfile | cut -d">" -f2 > Clusters"$numberofelements"Elements.txt

echo "output in: Clusters"$numberofelements"Elements.txt"
