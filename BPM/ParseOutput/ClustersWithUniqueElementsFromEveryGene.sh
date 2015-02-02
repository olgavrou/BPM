#!/bin/bash

# this script takes the mcl file that contains the clusters and the gene map file as arguments
# it finds the clusters that contain EXACTLY ONE element from EACH gene

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
