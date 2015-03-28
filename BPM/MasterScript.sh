#!/bin/bash

#-- MasterScript.sh ---------------------------------------------------
# 
# This script prepares the jobs, submits them and handles them
# It is the script that controls the program flow
#
# Arguments:
# 1. Input file
# 2. Timestamp so each run can have it's own instance
#
#----------------------------------------------------------------------

input=${1}
timestamp=${2}

query=`awk '/query_file/{print $2;}' $input`
geneMap=`awk '/gene_map/{print $2;}' $input`
rawDatabase=`awk '/raw_database/{print $2;}' $input`
readyDatabase=`awk '/ready_database/{print $2;}' $input`
option=`awk '/option/{print $2;}' $input`
I_or_E=`awk '/I_or_E/{print $2;}' $input`
F_or_C=`awk '/F_or_C/{print $2;}' $input`

################################################################################
#									       #
#				functions		                       #
#									       #
################################################################################

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


################################################################################
#                                                                              #
#               Initialize parameters, database and query file                 #
#                                                                              #
################################################################################

#### initialize some parameters ####
export LFC_HOST=`lcg-infosites --vo see lfc`
export LCG_CATALOG_TYPE=lfc
export LCG_GFAL_VO=see

#### session folder ####
sf="SessionFolder_$timestamp"
echo "This sessions folder is: $sf"
cp $input $sf
##### check and see which type of database I am provided with #####

if [[ -n $rawDatabase ]]; then
	echo "Creating database file"
	Unzip $rawDatabase
	# raw database, make the database file
	MakeFiles/MakeInputFile.sh $dataFolder
	if [[ $? != 0 ]]; then
		exit 2
	fi
	database="database.faa"
    mv $database $sf
else
	Unzip $readyDatabase
	database=$dataFolder
    cp $database $sf
fi

#### define query folder ####
if [[ $option == 5 ]]; then
	query=$database
else
	Unzip $query
	query=$dataFolder
    cp $query $sf
fi

################################################################################
#                                                                              #
#         Prepare jobs info, tools, needed folders, and upload them            #
#                                                                              #
################################################################################

echo "Preparing jobs..."
#### decompress the map folder if it is compressed and sort it ####
Unzip $geneMap
geneMap=$dataFolder
mv $geneMap tmp
sort tmp > "$geneMap"
rm -f tmp
cp $geneMap $sf
echo "......."
#### make the Info folder that the JobScript will use ####
if [[ $option == 1 || $option == 5 ]]; then
	# if the query file has sequences that are less than the maximum number of jobs (500) then run as many jobs as the number of query sequences
	# each job will have one sequence.
	# if the query file has more sequences than the max number of jobs, run max number of jobs and the query file will be split accordingly
	echo "......."
	numOfFiles=$(grep ">" -c $sf/$query)
	if [[ $numOfFiles -gt 500 ]]; then
		numOfFiles=104
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
		tools/makeblastdb -in $sf/$database -dbtype prot > /dev/null 2&>1
		awk '{print $0; exit;}' $sf/$query > $sf/pseudo.fasta
		echo "......."
		tools/blastp -query $sf/pseudo.fasta -db $sf/$database -out $sf/output.blastp > /dev/null 2&>1
		dbsize=$(awk '/total letters/{print $0; exit;}' $sf/output.blastp | cut -d";" -f 2 | cut -d" " -f 2 | sed 's/,//g')
		rm -f $sf/output.blastp $sf/pseudo.fasta
	else
		dbsize=""
	fi
	# also upload the query file and information for the running script to act on
	numOfFiles=$(wc -l < $sf/$geneMap)
	echo "$numOfFiles" > Info
	echo "$dbsize" >> Info
	echo "$query" >> Info
	echo "$database" >> Info
	echo "$geneMap" >> Info
	echo "$I_or_E" >> Info
	echo "$F_or_C" >> Info
fi
echo "......."
mv Info $sf

#### make the folder where everything will be uploaded ####
lfc-mkdir /grid/see/`whoami`/BPM_$timestamp
if [ $? != 0 ]; then
	exit 3
fi

#### make and upload the folder with the fasta files,gene map and Info file ####
mkdir fastafiles
cp $sf/$query $sf/$database $sf/$geneMap $sf/Info fastafiles
tar -zcvf fastafiles.tar.gz fastafiles > /dev/null 2&>1
tools/Upload.sh fastafiles.tar.gz `whoami` $timestamp
if [[ $? != 0 ]]; then
	rm -rf fastafiles*
	exit 3
fi
rm -rf fastafiles*

echo "......."
#### upload the tools folder ####
tar -zcvf tools.tar.gz tools > /dev/null

tools/Upload.sh tools.tar.gz `whoami` $timestamp
if [[ $? != 0 ]]; then
        rm -rf tools.tar.gz
	tools/RemoveFromSE.sh "BPM_$timestamp/fastafiles.tar.gz"
        exit 3
fi
rm -f tools.tar.gz

################################################################################
#                                                                              #
#          Calculate number of parametric jobs and submit them                 #
#                                                                              #
################################################################################

if [[ $numOfFiles -ge 50 ]]; then
        startNum=1
        jobsNum=50 # max 50 jobs per parametric job
        stopNum=$(( startNum + jobsNum))
        loopNum=$(( numOfFiles / jobsNum ))
        if [[ `echo "$numOfFiles % $jobsNum" | bc` -eq 0 ]]; then # no residue
                residue=0
        else
                residue=$( echo "$numOfFiles % $jobsNum" | bc )
        fi
else
        startNum=1
        jobsNum=$numOfFiles
        stopNum=$(( startNum + jobsNum))
        loopNum=1
        residue=0
fi

for i in `seq $loopNum`; do
        # make the job, submit it and follow it
        MakeFiles/MakeJDLFile.sh "Parametric" $startNum $stopNum "$sf/job$i.jdl" $option $timestamp $I_or_E
        glite-wms-job-submit -o $sf/jobID$i -a $sf/job$i.jdl > $sf/statusLog 2>&1
        error=$(grep "Error -" $sf/statusLog)
        if [[ -z $error ]]; then
                echo "Successfull job submition"
        else
                echo "Something is wrong with the Grid"
		for j in `seq $loopNum`; do
			echo "y" | glite-wms-job-cancel -i jobID$j > /dev/null 2>&1 
		done
                exit 3
        fi

        echo "Wait 2 minutes between job submitions..."
        sleep 120

        # next loop preparation
        startNum=$((startNum + jobsNum))
        stopNum=$(( startNum + jobsNum))
done
if [[ $residue -ne 0 ]]; then
        stopNum=$(( startNum + residue))
        # make the job, submit it and follow it
        MakeFiles/MakeJDLFile.sh "Parametric" $startNum $stopNum "$sf/job$(( i + 1 )).jdl" $option $timestamp $I_or_E
        glite-wms-job-submit -o $sf/jobID$((i + 1)) -a $sf/job$(( i + 1)).jdl > $sf/statusLog 2>&1
        error=$(grep "Error -" $sf/statusLog)
        if [[ -z $error ]]; then
                echo "Successfull job submition" 
        else
                echo "Something is wrong with the Grid"
                exit 3
        fi
        let loopNum++
fi

################################################################################
#                                                                              #
#                       Handle Parametric Jobs                                 #
#                                                                              #
################################################################################

HandleJobs/ParametricJobs.sh  $loopNum $timestamp $option $numOfFiles
exitstatus=$?
if [[ $exitstatus != 0 ]]; then
#	Cleanup $option $stopNum &
	exit $exitstatus
fi

################################################################################
#                                                                              #
#                  Prepare, submit and handle second job                       #
#                                                                              #
################################################################################

echo "the parametric jobs have terminated" | mail -s "Grid report" olgavrou@gmail.com # comment out later
echo "Parametric jobs have finished, preparing for the second job to run"

#### Second part, submit a job to construct mcl or phylogenetic profiles or both ####
case "$option" in

1) echo "Construct simple mcl clustering job is going to be submitted"
   MakeFiles/MakeJDLFile.sh "SimpleMcl" $numOfFiles $numOfFiles "$sf/secondjob.jdl" $option $timestamp $I_or_E 
   glite-wms-job-submit -o $sf/secondjob -a $sf/secondjob.jdl 2> /dev/null 
   echo "job has been submitted"
   HandleJobs/HandleSingleJob.sh $sf/secondjob $sf/secondjob.jdl "s" $option $timestamp
   exitstatus=$?
   ;;
2) echo "Construct simple phylogenetic profile job is going to be submitted"
   MakeFiles/MakeJDLFile.sh "PhylMcl" $numOfFiles $numOfFiles "$sf/secondjob.jdl" $option $timestamp
   glite-wms-job-submit -o $sf/secondjob -a $sf/secondjob.jdl 2> /dev/null 
   echo "job has been submitted"
   HandleJobs/HandleSingleJob.sh $sf/secondjob $sf/secondjob.jdl "s" $option $timestamp
   exitstatus=$?
  ;;
3) echo "Construct Phylogenetic Profile and its mcl clustering job is going to be submitted"
   MakeFiles/MakeJDLFile.sh "PhylMcl" $numOfFiles $numOfFiles "$sf/secondjob.jdl" $option $timestamp
   glite-wms-job-submit -o $sf/secondjob -a $sf/secondjob.jdl 2> /dev/null 
   echo "job has been submitted"
   HandleJobs/HandleSingleJob.sh $sf/secondjob $sf/secondjob.jdl "s" $option $timestamp
   exitstatus=$?
   ;;
4|5) echo "Do It All"
   # make a collection job and run them, one for simple mcl and the other for phyl profiles
   echo "Construct simple mcl clustering and Phylogenetic Profile job is going to be submitted"
   MakeFiles/MakeJDLFile.sh "SimpleMcl" $numOfFiles $numOfFiles "$sf/secondjob1.jdl" $option $timestamp $I_or_E
   MakeFiles/MakeJDLFile.sh "PhylMcl" $numOfFiles $numOfFiles "$sf/secondjob2.jdl" $option $timestamp
   mkdir $sf/jdl-collection
   mv $sf/secondjob1.jdl $sf/secondjob2.jdl $sf/jdl-collection/
   # submit a job collection
   glite-wms-job-submit -o $sf/secondjob -a --collection $sf/jdl-collection 2> /dev/null 
   echo "job has been submitted"
   HandleJobs/HandleSingleJob.sh $sf/secondjob "$sf/jdl-collection" "c" $option $timestamp
   exitstatus=$?
   ;;
esac

if [[ $exitstatus != 0 ]]; then
	exit $exitstatus	
fi

################################################################################
#                                                                              #
#           			Generate Report		                       #
#                                                                              #
################################################################################


echo "A small report will be found in Report.txt"
MakeFiles/GenerateReport.sh $timestamp
exit 0
