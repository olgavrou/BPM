#!/bin/bash

# for all parametric jobs
date

/bin/hostname -f
lcg-cr --version
# _PARAM_ is the fasta file part I need to select
param=${1}
fastaFile=${2}
toolbox=${3}
option=${4}

export LCG_CATALOG_TYPE=lfc
export LFC_HOST=lfc.isabella.grnet.gr
export LCG_GFAL_INFOSYS=bdii.isabella.grnet.gr:2170
export LCG_GFAL_VO=see

echo "parameter: $param"
# download needed tools
lcg-cp lfn:/grid/see/olgavrou/$toolbox.tar.gz file:$toolbox.tar.gz
# untar them
tar -zxvf $toolbox.tar.gz
mv $toolbox/* .

# download the fasta file
lcg-cp lfn:/grid/see/olgavrou/$fastaFile.tar.gz file:$fastaFile.tar.gz
# untar it
tar -zxvf $fastaFile.tar.gz
mv $fastaFile/* .

if [[ $option == 1 ]]; then
	# get the info
	splitNum=$(sed '1!d' Info)
	queryFile=$(sed '2!d' Info)
	db=$(sed '3!d' Info)

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
	
	# get the database that this job needs
	chmod +x SelectDatabaseGene.sh
	./SelectDatabaseGene.sh $database $map $param
	db="F$param"
fi  

echo "how many seq does query have?"
echo `grep -c ">" $query`
echo "how many seq does database have?"
echo `grep -c ">" $db`

#make blast database 
chmod +x makeblastdb
./makeblastdb -in $db -dbtype prot 
echo "makeblastdb finished, start blastp"  
#blast the query against the database
chmod +x blastp
if [[ $option == 1 ]]; then
	./blastp -query $query -db $db -out output.blastp -outfmt 6 
else 
	./blastp -query $query -db $db -out output.blastp -outfmt 6 -dbsize $dbsiz
fi
echo "blastp finished, make output.abc"
#make abc file to go through mcl
cut -f 1,2,11 output.blastp > output.abc

if [[ $option != 1 ]]; then
	# make abc file from which phylogenetic profiles will be created
	# the genomes identifier
	geneID=$(sed ''$param'!d' $map | cut -f 2)
	awk 'BEGIN{theFS=FS;}{if($0 ~ />/){FS=">";$0=$0;print $2;FS=theFS;}}' $query | awk '{print $1}' >> querySequences
	while read line; do
		found=$(grep -l "$line" output.abc)
		if [[ -z $found ]]; then
			echo -e "$line\t$geneID\t0" >> phyl$param.abc
		else
			echo -e "$line\t$geneID\t1" >> phyl$param.abc
		fi
	done < querySequences
fi

# check to see if something whent wrong and the output file wasn't created
isEmpty=$(find . -empty -name "output.abc")
if [[ -z $isEmpty ]]; then
	chmod +x Upload.sh
	case "$option" in
	1) echo "Simple mcl clustering"
	   echo "tar the output"
	   mv output.abc output$param.abc
	   tar -zcvf output$param.tar.gz output$param.abc
	   echo "upload the output.abc file"
	   ./Upload.sh output$param.tar.gz
	   ;;
	2|3) echo "Phylogenetic profile"
	   echo "tar the output"
	   tar -zcvf phyl$param.tar.gz phyl$param.abc
	   echo "upload the phyl.abc file"
	   ./Upload.sh phyl$param.tar.gz
	   ;;
	4) echo "Do It All" 
	   echo "tar the output"
	   tar -zcvf phyl$param.tar.gz phyl$param.abc
	   echo "upload the phylogenetic profile file"
	   ./Upload.sh phyl$param.tar.gz
	   echo "tar abc output"
	   mv output.abc output$param.abc
	   tar -zcvf output$param.tar.gz output$param.abc
	   ./Upload.sh output$param.tar.gz
	   ;;
	esac	
	echo "done"
else
	echo "PROBLEM OCCURED"
fi
date
