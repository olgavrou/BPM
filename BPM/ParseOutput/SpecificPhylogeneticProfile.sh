#!/bin/bash

#-- SpecificPhylogeneticProfile.sh --------------------------------------------
#
# This script returns the phylogenetic profiles of a specific
# protein
#
# Arguments: 
# 1. The file that contains the phylogenetic profiles
# 2. The specific protein identifier
#
# Output: <proteinID>PhylogeneticProfile.txt
#
#------------------------------------------------------------------------------


phylProfFile=${1}
proteinID=${2}

awk '{print;exit}' $phylProfFile > "$proteinID"PhylogeneticProfile.txt
echo "" >> "$proteinID"PhylogeneticProfile.txt
grep "^$proteinID" $phylProfFile >> "$proteinID"PhylogeneticProfile.txt

echo "output in: "$proteinID"PhylogeneticProfile.txt"
