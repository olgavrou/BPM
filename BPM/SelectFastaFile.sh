#!/bin/bash  


# $1 is the number of fasta files I want to split the input into
# $2 is the fasta file I am splitting
# $3 is the part of the fasta file that I will select

splitnum=${1}
fastaFile=${2}
sectionNum=${3}

# count the number of seq in the file
seqnum=$( grep -c ">" $fastaFile)
# if seqnum/splitnum is integer then sequence per file is

# seqnum/splitnum. If it is float then add one to seqnum.
if [[ -z "$splitnum" ]]
then 
	seqperfile=$seqnum
else 
 	if [[ `echo "$seqnum % $splitnum" | bc` -eq 0 ]]
  	then
     		seqperfile=$((seqnum / splitnum))
 	else
     		seqperfile=$(((seqnum / splitnum) + 1 ))
 	fi
fi

# start adding sequences to the file after startFrom sequences are counted
# startFrom is the sequence number after the last sequence added to the previous file (section)
startFrom=$(((sectionNum - 1)*seqperfile + 1))

# awk the fasta file, and for "seqperfile" sequences, print them to a numbered file

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



# check to see if all the files were created

#numFilesCreated=$(ls | grep "F[0-9]*.fasta" -c)
#if [[ $numFilesCreated -ne $splitnum ]]
#then
#	echo "The query was not split correctly"
#	exit 3
#fi
