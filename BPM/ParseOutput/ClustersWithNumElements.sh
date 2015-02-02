#!/bin/bash

# this script takes as arguments the mcl file and a number
# it returns the cluster ids of the clusters that have exactly that many elements 

mclfile=${1}
numberofelements=${2}

awk '{if(NF=='$((numberofelements + 1))'){print $1}}' $mclfile | cut -d">" -f2 > Clusters"$numberofelements"Elements.txt

echo "output in: Clusters"$numberofelements"Elements.txt"
