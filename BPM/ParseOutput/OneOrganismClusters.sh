#!/bin/bash

#-- OneOrganismClusters.sh --------------------------------------------------------------
# 
# This script returns a list with the cluster ids that contain
# elements from only one gene/organism, for all the gene/organisms in the gene map file
#
# Arguments: 
# 1. the mcl file that contains all of the clusters
# 2. the gene map
#
# Output: ClustersFromOneOrganism.txt
#
#----------------------------------------------------------------------------------------
 
mclfile=${1}
map=${2}


timestamp=$( date +"%Y%m%d%H%M%S")
echo "if the files are large, this may take a while"

if [[ -e "ClustersFromOneOrganism.txt" ]]; then
	rm ClustersFromOneOrganism.txt
fi

while read line; do
	gene=$line
	grep "$gene" $mclfile > ".tmpprot$timestamp"
	echo "$gene:" >> ClustersFromOneOrganism.txt
	while read line; do
		numGene=$(echo "$line" | awk '{for(i=1;i<=NF;i++){print $i}}' | grep "$gene" -c )
		numClusters=$(echo "$line" | awk 'END{print NF}' )
		if [[ $((numGene + 1)) == $numClusters ]]; then
			clusterid=$(echo "$line" | awk '{print $1}' | cut -d">" -f2)
			echo "$clusterid" >> ClustersFromOneOrganism.txt
		fi
	done < ".tmpprot$timestamp"
done < $map
rm ".tmpprot$timestamp"
echo "output in : ClustersFromOneOrganism.txt"
