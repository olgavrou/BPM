#!/bin/bash

# first argument is the input file

input=${1}

query=`awk '/query_file/{print $2;}' $input`
geneMap=`awk '/gene_map/{print $2;}' $input`
rawDatabase=`awk '/raw_database/{print $2;}' $input`
readyDatabase=`awk '/ready_database/{print $2;}' $input`
option=`awk '/option/{print $2;}' $input`

##############functions#########################################
Unzip(){
# takes the name of the zipped file or folder as an input and decompresses it
        folder=${1}
        mkdir tmpdir
        mv $folder tmpdir
        cd tmpdir
        if [[ "$folder" == *".zip" ]]; then
                unzip $folder
        elif [[ "$folder" == *".tar"  ]]; then
                tar -xvf $folder
        elif [[ "$folder" == *".tar.gz" ]]; then
                tar -zxvf $folder
	elif [[ "$folder" == *".gz" ]]; then
		gunzip $folder
        else
                echo "Not compressed"
                dataFolder=$folder
		mv $folder ..
		cd ..
		rm -rf tmpdir
                return 0
        fi

        mv $folder ..
        dataFolder=$(ls)
        mv $dataFolder ..
        cd ..
        rm -rf tmpdir
}
##### check and see which type of database I am provided with #####

if [[ -n $rawDatabase ]]
then
	echo "Raw Database"
	Unzip $rawDatabase
	./MakeInputFile.sh $dataFolder $geneMap
	database="database.faa"
else
	Unzip $readyDatabase
	database=$dataFolder
	echo "Ready Database"
fi


#### unzip the query if it is zipped

Unzip $query
query=$dataFolder
if [[ $option == 1 ]]; then
	# break the query to one sequence files and upload it to the grid
	# each file contains one query, otherwise split into the maximum number of jobs

	numOfFiles=$(grep ">" -c $query)
	if [[ $numOfFiles -gt 500 ]]; then
		numOfFiles=500
	fi
	echo "$numOfFiles"
	echo "$numOfFiles" > Info
	echo "$query" >> Info
	echo "$database" >> Info
else
	# run pseudo-blast for the whole database to get the effective db size
	./makeblastdb -in $database -dbtype prot
	awk '{print $0; exit;}' $query > pseudo.fasta
	./blastp -query pseudo.fasta -db $database -out output.blastp
	dbsize=$(awk '/total letters/{print $0; exit;}' output.blastp | cut -d";" -f 2 | cut -d" " -f 2 | sed 's/,//g')
	rm output.blastp pseudo.fasta
	# the number of jobs will be the number of genomes that we have
	# also upload the query file and information for the running job to act on
	numOfFiles=$(wc -l < $geneMap)
	echo "$numOfFiles"
	echo "$numOfFiles" > Info
	echo "$dbsize" >> Info
	echo "$query" >> Info
	echo "$database" >> Info
	echo "$geneMap" >> Info
fi

# make and upload the info folder
mkdir fastafiles
cp $query $database $geneMap Upload.sh Info fastafiles
tar -zcvf fastafiles.tar.gz fastafiles

./Upload.sh fastafiles.tar.gz

# make the job, submit it and follow it
./MakeJDLFile.sh "Parametric" $((numOfFiles +1)) "job.jdl" $option

glite-wms-job-submit -o jobID -a job.jdl
date > hello 
sleep 5

./HandlingParametricJobs.sh jobID job.jdl

timesResubmited=0
# look at resub file and check if/which nodes need resubmiting
# maybe make this part a separate script
resubmitJobs=$(wc -l < resub)
while [[ $resubmitJobs != 0 ]]; do
	if [[ $timesResubmited -lt 3 ]]; then
		# we don't want to resubmit the files for ever
        	timesResubmited=$((timesResubmited + 1))
        	rm jobResub jobResub.jdl
        	echo "some jobs need resubmiting"
        	echo "Parameters = {" > newPar
		flag=0
        	while read line; do
			if [[ $flag == 0 ]]; then
        	        	awk '{print $0,"'$line'"}' newPar > newParTemp
			else
				awk '{print $0,",'$line'"}' newPar > newParTemp
			fi
        	        mv newParTemp newPar
			flag=1;
        	done < resub
        	awk '{print $0,"};"}' newPar > newParTemp
        	mv newParTemp newPar
        	rm resub
        	awk '{if($0 !~ /Parameter/){print;}}' "job.jdl" >> jdlTemp
        	cat jdlTemp newPar > "jobResub.jdl"
        	rm jdlTemp newPar
        	glite-wms-job-submit -o jobResub -a jobResub.jdl
        	sleep 5
        	./HandlingParametricJobs.sh jobResub jobResub.jdl
		resubmitJobs=$(wc -l < resub)
	else 
		echo "something wrong and some files can not be run correctly"
		exit 7
	fi
done
echo "Parametric Job Finished"
rm  jobResub jobResub.jdl

# Second part
case "$option" in

1) echo "Simple mcl clustering"
   ./MakeJDLFile.sh "SimpleMcl" $numOfFiles "jobmcl.jdl" $option
   glite-wms-job-submit -o jobmcl -a jobmcl.jdl
   ./HandleSingleJob.sh jobmcl jobmcl.jdl "s"
   for i in `seq $numOfFiles`
   do
   	./RemoveFromSE.sh output$i.tar.gz
   done
   ;;
2) echo "Simple phylogenetic profile"
  # get the out files and concatenate them
  ./GetPhylProfAndConcatenateThem.sh $numOfFiles $query
  rm phyl*.abc
  ;;
3) echo "Phylogenetic Profile and its mcl clustering"
   ./MakeJDLFile.sh "PhylMcl" $numOfFiles "jobmcl.jdl" $option
   glite-wms-job-submit -o jobmcl -a jobmcl.jdl
   ./HandleSingleJob.sh jobmcl jobmcl.jdl "s"
   for i in `seq $numOfFiles`
   do
   	./RemoveFromSE.sh phyl$i.tar.gz
   done
   ;;
4) echo "Do It All"
   # make a collection job and run it, one for simple mcl and the other for mcl of phyl profiles
   ./MakeJDLFile.sh "SimpleMcl" $numOfFiles "job1.jdl" $option
   ./MakeJDLFile.sh "PhylMcl" $numOfFiles "job2.jdl" $option
   mkdir jdl-collection
   mv job1.jdl job2.jdl jdl-collection/
   # submit a job collection
   glite-wms-job-submit -o jobmcl -a --collection jdl-collection
   ./HandleSingleJob.sh jobmcl "jdl-collection" "c"
   for i in `seq $numOfFiles`
   do
   	./RemoveFromSE.sh phyl$i.tar.gz
	./RemoveFromSE.sh output$i.tar.gz
   done
  ;;
esac


./RemoveFromSE.sh fastafiles.tar.gz
# remove all the files that where created on ui and are not needed
rm -rf fastafiles* Info jobID* job*.jdl status_logjobID* statusjobID* resub jobmcl jobResub* querySequences jdl-collection
