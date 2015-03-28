#!/bin/bash

#-- SelectDatabaseGene.sh --------------------------------------------------------------------
#
# This script selects the protein sequences of a specific gene, from a fasta file
#
# Arguments:
# 1. The database fasta file
# 2. The database to organisms map
# 	the map has 1 column, with the organisms identifier in the database
# 3. The number (sequence in the map) of the gene that I want to select from the database
#
#---------------------------------------------------------------------------------------------

db=$1
map=$2
geneToSelect=$3

#count the number of organisms in the map
numOfOrganisms=$(wc -l < $map)
echo "number of organisms in the database: $numOfOrganisms"


#go through all of the organisms
  gene=$(sed ''$geneToSelect'!d' $map )
  
  awk '
     BEGIN{
	geneFile="F"'$geneToSelect';
	found="false";
     }
     {
	if($0 ~ /'$gene'/){
		print >> geneFile;
		found="true";
	}
 	else if(found == "true"){
          if($0 !~ />/){
             print >> geneFile;
           }
           else{
	     found="false";
           }
	}
     } 
   ' $db
