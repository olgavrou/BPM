#!/bin/bash

#-- ClusterPhylProfiles.sh ------------------------------------------
# 
# This script returns the phylogenetic profiles of the elements of
# of a specific cluster
#
# Arguments:
# 1. The mcl file that contains the clusters
# 2. The file that contains the phylogenetic profiles
# 4. A specific cluster id
#
# Output:
# Cluster<clusterID>ElementsPhylProf.txt
#
#--------------------------------------------------------------------

mclfile=${1}
phylProfFile=${2}
clusterID=${3}

grep ">$clusterID " $mclfile | awk '{for(i=2;i<=NF;i++){print $i}}' > .tmpelements
if [[ -e "Cluster"$clusterID"ElementsPhylProf.txt" ]]; then
	rm "Cluster"$clusterID"ElementsPhylProf.txt"
fi
while read line; do
	#echo "$line"
	grep "$line" $phylProfFile >> Cluster"$clusterID"ElementsPhylProf.txt
done < ".tmpelements"
rm .tmpelements
echo "output in: Cluster"$clusterID"ElementsPhylProf.txt"
