#!/bin/bash

#-- ClustersWithUniqueElements.sh -------------------------------------------------------
# 
# This script finds the clusters (their ids) that don't have more than one element
# of the same organism, i.e. there are no two (or more) elements from the same organism
#
# Arguments: 
# 1. The mcl file that contains all the clusters
# 2. The gene map file
#
# Output: UniqueElementClusters.txt
#
#----------------------------------------------------------------------------------------


mclfile=${1}
map=${2}

echo "if the files are large, this may take a while"

if [[ -e "UniqueElementClusters.txt" ]]; then
	rm UniqueElementClusters.txt
fi

while read line; do
	cluster=$line
	found=false
	while read line; do
		num=$( echo "$cluster" | awk '{for(i=1;i<=NF;i++){print $i}}' | grep "$line" -c )
		if [[ $num -gt 1 ]]; then
			found=false
			break
		fi
		found=true
	done < $map
	if [[ $found == true ]]; then
		clusterid=$(echo "$cluster" | awk '{print $1}' | cut -d">" -f2)
		echo "$clusterid" >> UniqueElementClusters.txt
	fi
done < $mclfile

echo "output in UniqueElementClusters.txt"
