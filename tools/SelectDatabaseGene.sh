#!/bin/bash

# first argument is the database
# second argument is the database to organisms map
# the map has 2 colums, one with the organism name and one with the organism identifier in the database
# third argument is the number (sequence in the map) of the gene that I want to select from the database


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
