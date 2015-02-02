#!/bin/bash

# this script takes the mcl file, the file that contains the phylogenetic profiles and a cluster id as arguments
# it returns the phylogenetic profiles of the elements in each cluster

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
