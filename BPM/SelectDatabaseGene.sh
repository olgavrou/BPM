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
#  rm tmp 
  #for this to work, the proteins for each genome should succeed one another
  #and the genomes should be in the same order as in the map?? test it a bit more
  gene=$(sed ''$geneToSelect'!d' $map | cut -f 2)
  #nextGene=$(sed ''$((lineNum + 1))'!d' $map | cut -f 2)
  #sed -n -r '/>'$gene'/,/>/p' $db >> F$gene
  grep -n "$gene" $db | cut -d ":" -f 1 > tmp
  lastLine=$(wc -l < tmp)
  firstSeqLine=$(sed '1!d' tmp)
  lastSeqLine=$(sed ''$lastLine'!d' tmp)
  
  awk '
     BEGIN{
	found=0;
	geneFile="F"'$geneToSelect';
     }
     {
	if(NR>='$firstSeqLine' && NR<='$lastSeqLine'){
	  print >> geneFile;
	}
	else if (NR<'$firstSeqLine'){
	  next;
        }
 	else if(NR>'$lastSeqLine'){
          if($0 !~ />/){
             print >> geneFile;
           }
           else{
             exit;
           }
	}
     } 
   ' $db

rm tmp
#(head -n $firstSeqLine > f2.txt ; head -n $((lastSeqLine - firstSeqLine +1)) > f1.txt ; cat >> f2.txt) < R0
#(head -n 24635 > f1.txt; cat > f2.txt) < R0  
