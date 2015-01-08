#!/bin/bash

# first argument is the jobid
# second argument is the job jdl file or the collection job folder
# third argument is "s" if it is one simple job or "c" if it is a collection

jobID=${1}
jdl=${2}
jobType=${3}
run="true"
fallAsleep=0
sameJobRuns=0

sleep 60
while $run; do
	if [[ $jobType == "s" ]]; then
		currentStatus=$(glite-wms-job-status -i $jobID | grep "Current Status" | cut -d":" -f 2 | tr -d ' ')
	elif [[ $jobType == "c" ]]; then
		currentStatus=$(glite-wms-job-status -i $jobID | grep "Current Status" -m 1 | cut -d":" -f 2 | tr -d ' ')
	fi
	echo "$currentStatus"
	if [[ $currentStatus == "Running" ]]; then
		echo "Running, wait for it to finish"
		sleep 60
	elif [[ $currentStatus == "Done(Success)" ]]; then
		echo "Done, get the output"
		glite-wms-job-output -i $jobID --dir mclOutput
		run="false"
	elif [[ $currentStatus == "Aborted" ]]; then
		echo "Job Aborted"
		run="false"
	elif [[ $currentStatus == "Cleared" ]]; then
		echo "job cleared"
		run="false"
	elif [[ $currentStatus == "Cancelled" ||  $currentStatus == "Done(Exit Code !=0)" ]]; then
		echo "Cancelled not by me or failed, need to resubmit it but keep count of the resubmitions"
		if [[ $sameJobRuns -lt 3 ]]; then                                      
                      	echo "y" | glite-wms-job-cancel -i $jobID                      
                    	rm $jobID               
			if [[ $jobType == "s" ]]; then                                       
                   		glite-wms-job-submit -o "$jobID" -a "$jdl"       
			elif [[ $jobType == "c" ]]; then
				glite-wms-job-submit -o "$jobID" -a --collection "$jdl"
			fi              
                    	sameJobRuns=$((sameJobRuns + 1))                               
                    	echo "cancelled and resubmitted"                               
               		continue                                                       
               	else
                        echo "Something is wrong with the grid"                        
	                run="false"                                                    
             	fi    	
	elif [[ $currentStatus == "Ready" ||  $currentStatus == "Submitted" || $currentStatus == "Scheduled" ]]; then
		echo "sleep for a while and if still not running then cancel and resubmit but only a number of times"
		if [[ $fallAsleep -lt 4 ]]; then
			echo "fall asleep"
			fallAsleep=$((fallAsleep + 1))
			sleep 60
			continue
		else
			if [[ $sameJobRuns -lt 3 ]]; then
				echo "y" | glite-wms-job-cancel -i $jobID
				rm $jobID
				if [[ $jobType == "s" ]]; then
					glite-wms-job-submit -o "$jobID" -a "$jdl"
				elif [[ $jobType == "c" ]]; then
					glite-wms-job-submit -o "$jobID" -a --collection "$jdl"
				fi
				sameJobRuns=$((sameJobRuns + 1))
				echo "cancelled and resubmitted"
				continue
			else
				echo "Something is wrong with the grid"
				run="false"
			fi
		fi
	fi
done
date >> hellomcl

# get the output
hasoutput=$(ls | grep "mclOutput")
if [[ -z $hasoutput ]]; then
	echo "no output"
else
	subdir=$(ls mclOutput)
	outLocation=mclOutput/$subdir

	cd $outLocation
	if [[ $jobType == "s" ]]; then
		tar -zxvf outmcl.tar.gz
		hasoutput=$(ls | grep "Out" | grep ".mcl")
		if [[ -z $hasoutput ]]; then
			echo "No output has been generated"
		else
			echo "Output is generated"
		fi
	elif [[ $jobType == "c" ]]; then
		ls | grep "Node" > outNodes
		while read line; do
			cd "$line"
			tar -zxvf outmcl.tar.gz
			hasoutput=$(ls | grep "Out" | grep ".mcl")
			if [[ -z $hasoutput ]]; then
	                        echo "No output has been generated"
        	        else
                		echo "Output is generated"
               		fi
			cd -	
		done < outNodes
		rm outNodes	
	fi
fi
