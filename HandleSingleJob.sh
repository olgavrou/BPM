#!/bin/bash

# This script handles a single job or a signle job collection and collects its output
# first argument is the jobid
# second argument is the job jdl file or the collection job folder
# third argument is "s" if it is one simple job or "c" if it is a collection
# the fourth argument is the option selected
# fifth argument is the timestamp of the folder where all the data is uploaded to

jobID=${1}
jdl=${2}
jobType=${3}
option=${4}
timestamp=${5}

run="true"
fallAsleep=0
sameJobRuns=0
getOutput="false"
echo "......."
sleep 60
while $run; do
	# get the jobs status
	if [[ $jobType == "s" ]]; then
		currentStatus=$(glite-wms-job-status -i $jobID 2>/dev/null | grep "Current Status" | cut -d":" -f 2 | tr -d ' ')
	elif [[ $jobType == "c" ]]; then
		currentStatus=$(glite-wms-job-status -i $jobID 2>/dev/null | grep "Current Status" -m 1 | cut -d":" -f 2 | tr -d ' ')
	fi
	# check the status
	if [[ $currentStatus == "Running" ]]; then
		echo "Job is Running, wait for it to finish"
		sleep 60
	elif [[ $currentStatus == "Done(Success)" ]]; then
		echo "Done, get the output"
		getOutput="true"
		run="false"
	elif [[ $currentStatus == "Aborted" ]]; then
		echo "Job Aborted"
		run="false"
		exit 5
	elif [[ $currentStatus == "Cancelled" ||  $currentStatus == "Done(Exit Code !=0)"  || $currentStatus == "Cleared" ]]; then
		echo "Job failed and will be resubmitted"
		if [[ $sameJobRuns -lt 3 ]]; then                                      
                      	echo "y" | glite-wms-job-cancel -i $jobID >> /dev/null 2>&1 
                    	rm $jobID               
			if [[ $jobType == "s" ]]; then                                       
                   		glite-wms-job-submit -o "$jobID" -a "$jdl" 2>/dev/null 
			elif [[ $jobType == "c" ]]; then
				glite-wms-job-submit -o "$jobID" -a --collection "$jdl" 2>/dev/null
			fi              
                    	let sameJobRuns++                                            
               		continue                                                       
               	else
                        echo "Something is wrong with the grid"                        
	                run="false"
			exit 4 
             	fi    	
	elif [[ $currentStatus == "Ready" ||  $currentStatus == "Submitted" || $currentStatus == "Scheduled" || $currentStatus == "Waiting" ]]; then
		echo "Waiting for the job to start running..."
		if [[ $fallAsleep -lt 10 ]]; then
			echo "......."
			let fallAsleep++
			sleep 60
			continue
		else
			echo "......."
			fallAsleep=0
			# resubmit
			if [[ $sameJobRuns -lt 3 ]]; then
				echo "y" | glite-wms-job-cancel -i $jobID >> /dev/null 2>&1
				rm $jobID
				if [[ $jobType == "s" ]]; then
					glite-wms-job-submit -o "$jobID" -a "$jdl" 2>/dev/null
				elif [[ $jobType == "c" ]]; then
					# list the contents of the grid and if output has been generated run only one job from the collection
					lcg-ls lfn:/grid/see/`whoami`/BPM_$timestamp > listoutput                    
                                	foundSimple=$(grep "resultssimple.tar.gz" listoutput)
                                	foundPhyl=$(grep "resultsphyl.tar.gz" listoutput)
					if [[ -z $foundSimple && -z $foundPhyl ]]; then
						glite-wms-job-submit -o "$jobID" -a --collection "$jdl" 2>/dev/null
					elif [[ -z $foundSimple ]]; then
						cp "$jdl"/"secondjob1.jdl" .
						jdl="secondjob1.jdl"
						jobType="s"
						glite-wms-job-submit -o "$jobID" -a "$jdl" 2>/dev/null
					elif [[ -z $foundPhyl ]]; then
						cp "$jdl"/"secondjob2.jdl" .
						jdl="secondjob2.jdl"
						jobType="s"
						glite-wms-job-submit -o "$jobID" -a "$jdl" 2>/dev/null
					fi
					rm listoutput	
				fi
				let sameJobRuns++
                                echo "Job failed and will be resubmitted"
                                continue
			else
				echo "Something is wrong with the grid"
				run="false"
				exit 4
			fi	
		fi
#	else
#		echo "Unknown error"
#		exit 6
	fi
done

############### decompress function ###########
Unzip(){
# takes the name of the zipped file or folder as an input and decompresses it
        folder=${1}
	outFolder=${2}
        mkdir tmpdir
        mv $folder tmpdir
        cd tmpdir
        tar -zxvf $folder
        rm $folder
        dataFolder=$(ls)
        mv $dataFolder ../$outFolder/
        cd ..
        rm -rf tmpdir
}

if [[ $getOutput == "true" ]]; then
	export LCG_CATALOG_TYPE=lfc
	export LFC_HOST=lfc.isabella.grnet.gr
	export LCG_GFAL_INFOSYS=bdii.isabella.grnet.gr:2170
	export LCG_GFAL_VO=see
	# make folder for the output to be stored
	if [[ -d "MyOutput" ]]; then
		i=1
		while [[ -d "MyOutput$i" ]]; do
			let i++
		done
		mkdir "MyOutput$i"
		outputFolder="MyOutput$i"
	else
		mkdir MyOutput
		outputFolder="MyOutput"
	fi
	# get the output
 	case $option in
	
	1) lcg-cp lfn:/grid/see/`whoami`/BPM_$timestamp/resultssimple.tar.gz file:resultssimple.tar.gz
	Unzip resultssimple.tar.gz $outputFolder
	echo "results in: $outputFolder"
	;;
	2|3) lcg-cp lfn:/grid/see/`whoami`/BPM_$timestamp/resultsphyl.tar.gz file:resultsphyl.tar.gz 
	Unzip resultsphyl.tar.gz $outputFolder
        echo "results in: $outputFolder"
	;;
	4|5) lcg-cp lfn:/grid/see/`whoami`/BPM_$timestamp/resultssimple.tar.gz file:resultssimple.tar.gz
	lcg-cp lfn:/grid/see/`whoami`/BPM_$timestamp/resultsphyl.tar.gz file:resultsphyl.tar.gz
	Unzip resultssimple.tar.gz $outputFolder
	echo "results in: $outputFolder"
	Unzip resultsphyl.tar.gz $outputFolder
	echo "results in: $outputFolder" 
	;;
	esac
	echo "Your results are in the folder: $outputFolder" > Report.txt
else
	echo "No output generated" > Report.txt
fi
