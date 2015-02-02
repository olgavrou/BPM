#!/bin/bash

# this script takes as arguments the genome or protein ID whose clusters we are looking for, and the mcl file that contains the cluster IDs
# output is a file named <ID>_clusters.txt

ID=${1}
mclfile=${2}

grep "$ID" $mclfile | awk '{print $1}' | cut -d">" -f2 > "$ID"_clusters.txt

echo "Output in "$ID"_clusters.txt"
