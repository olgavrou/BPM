#!/bin/bash

# first argument is the input file
# second argument is the timestamp so the app can upload the files created to a specific folder

input=${1}
timestamp=${2}

query=`awk '/query_file/{print $2;}' $input`
geneMap=`awk '/gene_map/{print $2;}' $input`
rawDatabase=`awk '/raw_database/{print $2;}' $input`
readyDatabase=`awk '/ready_database/{print $2;}' $input`
option=`awk '/option/{print $2;}' $input`
I_or_E=`awk '/I_or_E/{print $2;}' $input`
F_or_C=`awk '/F_or_C/{print $2;}' $input`
##############functions#########################################
Unzip(){
# takes the name of the compressed file or folder as an input and decompresses it
        folder=${1}
        mkdir tmpdir
        mv $folder tmpdir
        cd tmpdir
        if [[ "$folder" == *".zip" ]]; then
                unzip $folder > /dev/null 2&>1
        elif [[ "$folder" == *".tar"  ]]; then
                tar -xvf $folder > /dev/null 2&>1
        elif [[ "$folder" == *".tar.gz" ]]; then
                tar -zxvf $folder > /dev/null 2&>1
	elif [[ "$folder" == *".gz" ]]; then
		gunzip $folder > /dev/null 2&>1
        else
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

Cleanup(){
	# arguments are the option and the number of files to be cleaned up (=number of jobs)
	op=${1}
	removeNum=${2}
	./RemoveFromSE.sh "BPM_$timestamp/fastafiles.tar.gz"
	./RemoveFromSE.sh "BPM_$timestamp/tools.tar.gz"
	rm -rf fastafiles* Info jobID* job*.jdl status_logjobID* statusjobID* secondjob* jdl-collection tools* $database
	
	case "$op" in
	1)
   		for i in `seq $removeNum`
   		do
        		./RemoveFromSE.sh "BPM_$timestamp/output$i.tar.gz"
   		done
   	;;
	2|3)
   		for i in `seq $removeNum`
   		do
        		./RemoveFromSE.sh "BPM_$timestamp/phyl$i.tar.gz"
   		done
 	;;
	4|5)
   		for i in `seq $removeNum`
   		do
        		./RemoveFromSE.sh "BPM_$timestamp/phyl$i.tar.gz"
        		./RemoveFromSE.sh "BPM_$timestamp/output$i.tar.gz"
        		if [[ $op == 5 ]]; then
                		./RemoveFromSE.sh "BPM_$timestamp/PhylProf$i.tar.gz"
        		fi
   		done
  	;;
	esac
	./RemoveFromSE.sh "BPM_$timestamp/resultsphyl.tar.gz"
	./RemoveFromSE.sh "BPM_$timestamp/resultssimple.tar.gz"
	#remove the folder
	lfc-rm -r /grid/see/`whoami`/BPM_$timestamp
	echo "Clean up is done, good bye"
}

#### initialize some parameters ####
export LFC_HOST=`lcg-infosites --vo see lfc`
export LCG_CATALOG_TYPE=lfc
export LCG_GFAL_VO=see

##### check and see which type of database I am provided with #####

if [[ -n $rawDatabase ]]; then
	echo "Creating database file"
	Unzip $rawDatabase
	# raw database, make the database file
	./MakeInputFile.sh $dataFolder
	if [[ $? != 0 ]]; then
		exit 2
	fi
	database="database.faa"
else
	Unzip $readyDatabase
	database=$dataFolder
fi

#### define query folder ####
if [[ $option == 5 ]]; then
	query=$database
else
	Unzip $query
	query=$dataFolder
fi

echo "Preparing jobs..."
#### decompress the map folder if it is compressed and sort it ####
Unzip $geneMap
geneMap=$dataFolder
mv $geneMap tmp
sort tmp > "$geneMap"
rm tmp
echo "......."
#### make the Info folder that the JobScript will use ####
if [[ $option == 1 || $option == 5 ]]; then
	# if the query file has sequences that are less than the maximum number of jobs (500) then run as many jobs as the number of query sequences
	# each job will have one sequence.
	# if the query file has more sequences than the max number of jobs, run max number of jobs and the query file will be split accordingly
	echo "......."
	numOfFiles=$(grep ">" -c $query)
	if [[ $numOfFiles -gt 500 ]]; then
		numOfFiles=500
	fi
	echo "$numOfFiles" > Info
	echo "$query" >> Info
	echo "$database" >> Info
	echo "$geneMap" >> Info
	echo "$I_or_E" >> Info
	echo "$F_or_C" >> Info
else
	echo "......."
	# split the database option. Number of jobs is the number of oranisms specified in the geneMap file
	# run pseudo-blast for the whole database to get the effective db size if I want e-values
	if [[ $I_or_E == "E" ]]; then
		tools/makeblastdb -in $database -dbtype prot > /dev/null 2&>1
		awk '{print $0; exit;}' $query > pseudo.fasta
		echo "......."
		tools/blastp -query pseudo.fasta -db $database -out output.blastp > /dev/null 2&>1
		dbsize=$(awk '/total letters/{print $0; exit;}' output.blastp | cut -d";" -f 2 | cut -d" " -f 2 | sed 's/,//g')
		rm output.blastp pseudo.fasta
	else
		dbsize=""
	fi
	# also upload the query file and information for the running script to act on
	numOfFiles=$(wc -l < $geneMap)
	echo "$numOfFiles"
	echo "$numOfFiles" > Info
	echo "$dbsize" >> Info
	echo "$query" >> Info
	echo "$database" >> Info
	echo "$geneMap" >> Info
	echo "$I_or_E" >> Info
	echo "$F_or_C" >> Info
fi
echo "......."

#### make the folder where everything will be uploaded ####
lfc-mkdir /grid/see/`whoami`/BPM_$timestamp

#### make and upload the folder with the fasta files,gene map and Info file ####
mkdir fastafiles
cp $query $database $geneMap Info fastafiles 2>/dev/null
tar -zcvf fastafiles.tar.gz fastafiles > /dev/null 2&>1
./Upload.sh fastafiles.tar.gz `whoami` $timestamp
if [[ $? != 0 ]]; then
	rm -rf Info fastafiles*
	exit 3
fi
echo "......."
#### upload the tools folder ####
tar -zcvf tools.tar.gz tools > /dev/null

./Upload.sh tools.tar.gz `whoami` $timestamp
if [[ $? != 0 ]]; then
        rm -rf Info fastafiles* tools*
	./RemoveFromSE.sh "BPM_$timestamp/fastafiles.tar.gz"
        exit 3
fi

#### make the jdl, submit the parametric job and follow it ####
./MakeJDLFile.sh "Parametric" $((numOfFiles + 1)) "job.jdl" $option $timestamp
echo "submitting the $numOfFiles jobs"
glite-wms-job-submit -o jobID -a job.jdl 2>/dev/null
date +"%Y%m%d %T" > TimeParametricJobs # keep the time it started running 
echo "the jobs have been submitted"
sleep 5

./HandlingParametricJobs.sh jobID job.jdl $timestamp $option
exitstatus=$?
if [[ $exitstatus != 0 ]]; then
#	Cleanup $option $stopNum &
	exit $exitstatus
fi

echo "the parametric jobs have terminated" | mail -s "Grid report" olgavrou@gmail.com # comment out later
echo "Parametric jobs have finished, preparing for the second job to run"
date +"%Y%m%d %T" >> TimeParametricJobs # time they finished
date +"%Y%m%d %T" > TimeSimpleJob
#### Second part, submit a job to construct mcl or phylogenetic profiles or both ####
case "$option" in

1) echo "Construct simple mcl clustering job is going to be submitted"
   ./MakeJDLFile.sh "SimpleMcl" $numOfFiles "secondjob.jdl" $option $timestamp $I_or_E 
   glite-wms-job-submit -o secondjob -a secondjob.jdl 2> /dev/null 
   echo "job has been submitted"
   ./HandleSingleJob.sh secondjob secondjob.jdl "s" $option $timestamp
   exitstatus=$?
   ;;
2) echo "Construct simple phylogenetic profile job is going to be submitted"
   ./MakeJDLFile.sh "PhylMcl" $numOfFiles "secondjob.jdl" $option $timestamp
   glite-wms-job-submit -o secondjob -a secondjob.jdl 2> /dev/null 
   echo "job has been submitted"
   ./HandleSingleJob.sh secondjob secondjob.jdl "s" $option $timestamp
   exitstatus=$?
  ;;
3) echo "Construct Phylogenetic Profile and its mcl clustering job is going to be submitted"
   ./MakeJDLFile.sh "PhylMcl" $numOfFiles "secondjob.jdl" $option $timestamp
   glite-wms-job-submit -o secondjob -a secondjob.jdl 2> /dev/null 
   echo "job has been submitted"
   ./HandleSingleJob.sh secondjob secondjob.jdl "s" $option $timestamp
   exitstatus=$?
   ;;
4|5) echo "Do It All"
   # make a collection job and run them, one for simple mcl and the other for phyl profiles
   echo "Construct simple mcl clustering and Phylogenetic Profile job is going to be submitted"
   ./MakeJDLFile.sh "SimpleMcl" $numOfFiles "secondjob1.jdl" $option $timestamp $I_or_E
   ./MakeJDLFile.sh "PhylMcl" $numOfFiles "secondjob2.jdl" $option $timestamp
   mkdir jdl-collection
   mv secondjob1.jdl secondjob2.jdl jdl-collection/
   # submit a job collection
   glite-wms-job-submit -o secondjob -a --collection jdl-collection 2> /dev/null 
   echo "job has been submitted"
   ./HandleSingleJob.sh secondjob "jdl-collection" "c" $option $timestamp
   exitstatus=$?
   ;;
esac
date +"%Y%m%d %T" >> TimeSimpleJob
if [[ $exitstatus != 0 ]]; then
#       Cleanup $option $stopNum &
	rm TimeSimpleJob TimeParametricJobs
	exit $exitstatus	
fi

#Cleanup $option $numOfFiles &

echo "Job is done and cleanup will be running on background. You will be informed when it is finished"
echo "It may take up to one hour to clean up for big files"
echo "In the mean time you may access the generated output, but are not advised to close your shell session"
echo "A small report will be found in Report.txt"
./GenerateReport.sh $numOfFiles $option "TimeParametricJobs" "TimeSimpleJob"
exit 0
