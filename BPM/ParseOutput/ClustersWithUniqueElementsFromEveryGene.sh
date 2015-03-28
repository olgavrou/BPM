#!/bin/bash

#-- ClustersWithUniqueElementsFromEveryGene.sh ------------------------------------------
#
# This script finds the clusters (their ids) that contain EXACTLY ONE 
# element form EACH gene
#
# Arguments:
# 1. The mcl file that contains all the clusters
# 2. the gene map file
#
# Output: UniqueElementFromEachGeneClusters.txt
#
#----------------------------------------------------------------------------------------

mclfile=${1}
map=${2}

echo "if the files are large, this may take a while"

if [[ -e "UniqueElementFromEachGeneClusters.txt" ]]; then
	rm UniqueElementFromEachGeneClusters.txt
fi

while read line; do
	cluster=$line
	found=false
	while read line; do
		num=$( echo "$cluster" | awk '{for(i=1;i<=NF;i++){print $i}}' | grep "$line" -c )
		if [[ $num != 1 ]]; then
			found=false
			break
		fi
		found=true
	done < $map
	if [[ $found == true ]]; then
		clusterid=$(echo "$cluster" | awk '{print $1}' | cut -d">" -f2)
		echo "$clusterid" >> UniqueElementFromEachGeneClusters.txt
	fi
done < $mclfile

echo "output in UniqueElementFromEachGeneClusters.txt"
