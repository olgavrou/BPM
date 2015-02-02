#!/bin/bash

phylProfFile=${1}
proteinID=${2}

awk '{print;exit}' $phylProfFile > "$proteinID"PhylogeneticProfile.txt
echo "" >> "$proteinID"PhylogeneticProfile.txt
grep "^$proteinID" $phylProfFile >> "$proteinID"PhylogeneticProfile.txt

echo "output in: "$proteinID"PhylogeneticProfile.txt"
