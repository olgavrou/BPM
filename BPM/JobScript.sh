#!/bin/bash

#-- JobScript.sh ------------------------------------------------------
# 
# This script blasts the query against the database 
# file and according to the option parameter, works on the phylogenetic 
# profiling or not
#
# Arguments:
# 1. The parametric jobs unique_PARAM_
# 2. The fastafile name
# 3. The tools folder name
# 4. The selected program option
# 5. User name for down and uploading files to the grid
# 6. Instance timestamp
#
#----------------------------------------------------------------------

date +"%Y%m%d %T"

/bin/hostname -f
lcg-cr --version
# _PARAM_ is the part I need to select from the query file or the database file
param=${1}
fastaFile=${2}
toolbox=${3}
option=${4}
userName=${5}
timestamp=${6}

export LFC_HOST=`lcg-infosites --vo see lfc`
export LCG_CATALOG_TYPE=lfc
export LCG_GFAL_VO=see

################################################################################
#                                                                              #
#                         Get Jobs tools and Info                              #
#                                                                              #
################################################################################

echo "parameter: $param"
echo "Check to see if jobs already ran"
lcg-ls lfn:/grid/see/$userName/BPM_$timestamp/output$param.tar.gz
if [[ $? == 0 ]]; then
	echo "job already ran"	
	exit
fi
lcg-ls lfn:/grid/see/$userName/BPM_$timestamp/phyl$param.tar.gz
if [[ $? == 0 ]]; then
        echo "job already ran"  
        exit
fi
# download needed tools
lcg-cp lfn:/grid/see/$userName/BPM_$timestamp/$toolbox.tar.gz file:$toolbox.tar.gz
# untar them
tar -zxvf $toolbox.tar.gz
mv $toolbox/* .

# download the fasta file
lcg-cp lfn:/grid/see/$userName/BPM_$timestamp/$fastaFile.tar.gz file:$fastaFile.tar.gz
# untar them
tar -zxvf $fastaFile.tar.gz
mv $fastaFile/* .

if [[ $option == 1 || $option == 5 ]]; then
	# get the info
	splitNum=$(sed '1!d' Info)
	queryFile=$(sed '2!d' Info)
	db=$(sed '3!d' Info)
	map=$(sed '4!d' Info)
	I_or_E=$(sed '5!d' Info)
	F_or_C=$(sed '6!d' Info) # ingored in option 1
	# get the query that this job needs
	chmod +x SelectFastaFile.sh
	./SelectFastaFile.sh $splitNum $queryFile $param
	query="F$param.fasta"
else
	# get the info
	genomeNum=$(sed '1!d' Info)
	dbsiz=$(sed '2!d' Info)
	query=$(sed '3!d' Info)
	database=$(sed '4!d' Info)
	map=$(sed '5!d' Info) 
	I_or_E=$(sed '6!d' Info)
	F_or_C=$(sed '7!d' Info)
	# get the database that this job needs
	chmod +x SelectDatabaseGene.sh
	./SelectDatabaseGene.sh $database $map $param
	db="F$param"
fi  

echo "how many seq does query have?"
echo `grep -c ">" $query`
echo "how many seq does database have?"
echo `grep -c ">" $db`

################################################################################
#                                                                              #
#                               BLAST                                          #
#                                                                              #
################################################################################

# make blast database
chmod +x makeblastdb
./makeblastdb -in $db -dbtype prot 
echo "makeblastdb finished, start blastp"  
# run the query against the database
chmod +x blastp
if [[ $option == 1 || $option == 5 || $I_or_E != "E" ]]; then
	./blastp -query $query -db $db -out output.blastp -outfmt 6 
else 
	./blastp -query $query -db $db -out output.blastp -outfmt 6 -dbsize $dbsiz
fi
echo "blastp finished, make output.abc"
# make abc file to go through mcl
# if chosen E value then cut 11 field
# if chosen I or empty (the default) then cut 3 field
if [[ $I_or_E == "E" ]]; then
	cut -f 1,2,11 output.blastp > output.abc
else
	cut -f 1,2,3 output.blastp > output.abc
fi

################################################################################
#                                                                              #
#                        Phylogenetic Profiles                                 #
#                                                                              #
################################################################################

echo "making phyl abc"
date +"%Y%m%d %T"
case "$option" in
	2|3|4) echo "split database selection"

	# make phylogenetic profile
	# the genomes identifier
	geneID=$(sed ''$param'!d' $map )
	awk 'BEGIN{theFS=FS;}{if($0 ~ />/){FS=">";$0=$0;print $2;FS=theFS;}}' $query | awk '{print $1}' >> querySequences
	while read line; do
		found=$(grep -w "^$line" -c output.abc)
		if [[ $found == 0 ]]; then
			echo -e "$line\t$geneID\t0" >> phyl$param.abc
		else
			if [[ $F_or_C == "C" ]]; then
				# if C then how many times is it found?
				# else if F or empty (the default) then 1 for hit
				echo -e "$line\t$geneID\t$found" >> phyl$param.abc
			else
				echo -e "$line\t$geneID\t1" >> phyl$param.abc
			fi
		fi
	done < querySequences
	;;
	5) echo "all-vs-all option"
	awk 'BEGIN{theFS=FS;}{if($0 ~ />/){FS=">";$0=$0;print $2;FS=theFS;}}' $query | awk '{print $1}' >> querySequences
	while read line; do
        geneNum=$(wc -l < $map)
        for i in `seq $geneNum` ; do
                geneID=$(sed ''$i'!d' $map )
                found=$(grep -w "^$line" output.abc | cut -f 2 | grep "$geneID" -c)
                if [[ $found == 0 ]]; then
                        echo -e "$line\t$geneID\t0" >> phyl$param.abc
                else
                        if [[ $F_or_C == "C" ]]; then
                                # if C then how many times is it found?
                                # else if F or empty (the default) then 1 for hit
                                echo -e "$line\t$geneID\t$found" >> phyl$param.abc
                        else
                                echo -e "$line\t$geneID\t1" >> phyl$param.abc
                        fi
                fi
        done
	done < querySequences

	echo "one liner"
	date +"%Y%m%d %T"
	while read line; do
        	grep -w "$line" phyl$param.abc | cut -f 3 | sed 's/^//' | tr '\n' ' ' > tmp
        	echo "$line `cat tmp`"  >> PhylProf$param
        	rm tmp
	done < querySequences
	;;
esac
date +"%Y%m%d %T"
echo "done making phyl abc"

################################################################################
#                                                                              #
#                           Upload output                                      #
#                                                                              #
################################################################################

# check to see if something whent wrong and the output file wasn't created
ishere=$(ls | grep "output.abc")
isEmpty=$(find . -empty -name "output.abc")
if [[ ! -z $ishere  && -z $isEmpty ]]; then
	chmod +x Upload.sh
	case "$option" in
	1) echo "Simple mcl clustering"
	   echo "tar the output"
	   mv output.abc output$param.abc
	   tar -zcvf output$param.tar.gz output$param.abc
	   echo "upload the output.abc file"
	   ./Upload.sh output$param.tar.gz $userName $timestamp
	   ;;
	2|3) echo "Phylogenetic profile"
	   mapLineCount=$(cat $map | wc -l)
           queryLineCount=$(cat querySequence | wc -l)
           ppLineCount=$(cat phyl$param.abc | wc -l)
           if [[ $ppLineCount == $((mapLineCount*queryLineCount))  ]]; then
	   	echo "tar the output"
	   	tar -zcvf phyl$param.tar.gz phyl$param.abc
	   	echo "upload the phyl.abc file"
	   	./Upload.sh phyl$param.tar.gz $userName $timestamp
	   else
	   	echo "Output not good"
	   fi
	   mv output.abc output$param.abc
	   tar -zcvf output$param.tar.gz output$param.abc
	   echo "upload the output.abc file"
	   ./Upload.sh output$param.tar.gz $userName $timestamp
	   ;;
	4) echo "Do It All" 
	   echo "tar the output"
	   mapLineCount=$(cat $map | wc -l)
           queryLineCount=$(cat querySequence | wc -l)
           ppLineCount=$(cat phyl$param.abc | wc -l)
           if [[ $ppLineCount == $((mapLineCount*queryLineCount))  ]]; then
	   	tar -zcvf phyl$param.tar.gz phyl$param.abc
	   	echo "upload the phylogenetic profile abc file"
	   	./Upload.sh phyl$param.tar.gz $userName $timestamp
	   else
	   	echo "Output not good"
	   fi
	   echo "tar abc output"
	   mv output.abc output$param.abc
	   tar -zcvf output$param.tar.gz output$param.abc
	   ./Upload.sh output$param.tar.gz $userName $timestamp
	   ;;
	5) echo "Do It All all-vs-all"
	   echo "tar the output"
           queryLineCount=$(cat querySequence | wc -l)
           ppLineCount=$(cat PhylProf$param | wc -l)
           if [[ $ppLineCount == $queryLineCount ]]; then
	   	tar -zcvf phyl$param.tar.gz phyl$param.abc
	   	echo "upload the phylogenetic profile abc file"
           	./Upload.sh phyl$param.tar.gz $userName $timestamp
	   	echo "tar and upload the phylogenetic profile"
	   	tar -zcvf PhylProf$param.tar.gz PhylProf$param
	   	./Upload.sh PhylProf$param.tar.gz $userName $timestamp
	   else
	   	echo "Output not good"
	   fi
           echo "tar abc output"
           mv output.abc output$param.abc
           tar -zcvf output$param.tar.gz output$param.abc
           ./Upload.sh output$param.tar.gz $userName $timestamp
	   ;;
	esac	
	echo "done"
else
	echo "PROBLEM OCCURED"
fi
date +"%Y%m%d %T"
