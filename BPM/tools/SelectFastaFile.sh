#!/bin/bash 

#-- SelectFastaFile.sh --------------------------------------------------------
# 
# This script selects a number of protein sequences from a fasta file
#
# Arguments:
# 1. The number of fasta files I want to split the input into
# 2. The fasta file I am splitting
# 3. The part of the fasta file that I will select

splitnum=${1}
fastaFile=${2}
sectionNum=${3}

# count the number of seq in the file
seqnum=$( grep -c ">" $fastaFile)

if [[ -z "$splitnum" ]]
then 
	seqperfile=$seqnum
else 
   	seqperfile=$((seqnum / splitnum))
fi

# start adding sequences to the file after startFrom sequences are counted
# startFrom is the sequence number after the last sequence added to the previous file (section)
startFrom=$(((sectionNum - 1)*seqperfile + 1))

# awk the fasta file, and for "seqperfile" sequences, print them to a numbered file
if [[ $splitnum != $sectionNum ]];then
	# not the last piece
	awk '
	BEGIN{
      		part="F"'$sectionNum'".fasta";
      		i=0;
      		seqperfile='$seqperfile';
		seqCount=0;
 	}
 	{
		if($0 ~ />/ && seqCount != '$startFrom'){
			seqCount++;
		}

		if(seqCount == '$startFrom'){
      			while(i<=seqperfile){
         			if($0 ~ />/){
            				i++;
            				if(i>seqperfile){
              					break;
           				 }
        			} 
         			print >> part;
         			next;
     	 		} 
		}
      
 	}' $fastaFile

else
        # the last piece
        awk '
        BEGIN{
                part="F"'$sectionNum'".fasta";
                i=0;
                seqperfile='$seqperfile';
                seqCount=0;
        }
        {
                if($0 ~ />/ && seqCount != '$startFrom'){
                        seqCount++;
                }

                if(seqCount == '$startFrom'){ 
                	print >> part;        
                }
      
        }' $fastaFile
fi
