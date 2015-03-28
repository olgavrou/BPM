#!/bin/bash

#-- ClusterSequences.sh -----------------------------------------------------------------
#
# This script returns the protein sequences of all the elements that belong 
# to a specific cluster
#
# Arguments:
# 1. A specific cluster id
# 2. The mcl file that contains all the clusters
# 3. The fasta file that holds the sequences (e.g. tha database fasta file)
# 4. Another fasta file that holds the sequences (e.g. the query fasta file) [optional]
#
# Output: Cluster<clusterID>Sequences.fasta
#
#----------------------------------------------------------------------------------------


cluster=${1}
mclfile=${2}
fastafile1=${3}
fastafile2=${4}

timestamp=$( date +"%Y%m%d%H%M%S")

echo "if the fasta files are large, this may take a while"

awk '/>'$cluster' /{print; exit;}' $mclfile | sed 's/>'$cluster'//' | awk '{for(i=1;i<=NF;i++){print $i}}' > ".tmpprot$timestamp"
if [[ -e "Cluster"$cluster"Sequences.fasta" ]]; then
	rm Cluster"$cluster"Sequences.fasta
fi
while read line; do
	l=$( grep -no "$line" $fastafile1 | cut -d":" -f1 )
	awk 'BEGIN{found="no"}{if(NR=='$l'){print;found="yes";next;}if(found == "yes"){if($0 !~ />/){print;}else{exit;}}}' $fastafile1 >> Cluster"$cluster"Sequences.fasta
	if [[ ! -z $fastafile2 ]]; then
		awk 'BEGIN{found="no"}{if(NR=='$l'){print;found="yes";next;}if(found == "yes"){if($0 !~ />/){print;}else{exit;}}}' $fastafile2 >> Cluster"$cluster"Sequences.fasta
	fi
done < ".tmpprot$timestamp"
rm ".tmpprot$timestamp"
echo "output in Cluster"$cluster"Sequences.fasta"
