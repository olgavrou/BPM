#!/bin/bash 

#-- HandleSingleJob.sh -------------------------------------------------------------------- 
# 
# This script handles a single job or a signle job collection and collects its output
# 
# Arguments:
# 1. The jobid
# 2. The job jdl file or the collection job folder
# 3. "s" if it is one simple job or "c" if it is a collection
# 4. The option selected
# 5. The timestamp of the folder where all the data is uploaded to
#
#------------------------------------------------------------------------------------------

jobID=${1}
jdl=${2}
jobType=${3}
option=${4}
timestamp=${5}

################################################################################
#                                                                              #
#                               functions                                      #
#                                                                              #
################################################################################

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

Time(){
# get the time difference of the two timestamps
        timestamp1=${1}
        timestamp2=${2}
        t=$(date -d "$timestamp1" +%s)
        t1=$(date -d "$timestamp2" +%s)
        diff=$(expr $t1 - $t)

}

CancelAndResubmit(){
	echo "y" | glite-wms-job-cancel -i $jobID >> /dev/null 2>&1
      	rm $jobID
       	jdlTmp=$( echo "$jdl" | cut -d"/" -f2)
       	if [[ $jobType == "s" ]]; then
   	    	error=$(glite-wms-job-submit -o "$jobID" -a $sf/"$jdlTmp" 2>$1 | grep "Error -")
       	elif [[ $jobType == "c" ]]; then
        	error=$(glite-wms-job-submit -o "$jobID" -a --collection $sf/"$jdlTmp" 2>&1 | grep "Error -")
       	fi
     
	if [[ -z $error ]]; then
        	echo "New job submitted"
		return 0
	else
		return 1
	fi
}

################################################################################
#                                                                              #
#                            Control the job flow                              #
#                                                                              #
################################################################################

sf="SessionFolder_$timestamp"
run="true"
fallAsleep=0
sameJobRuns=0
getOutput="false"
echo "......."
sleep 60
startTime=$(date +"%Y%m%d %T")

# run until job is done
while $run; do

	# get the jobs status
	if [[ $jobType == "s" ]]; then
		currentStatus=$(glite-wms-job-status -i $jobID 2>&1 | grep "Current Status" | cut -d":" -f 2 | tr -d ' ')
	elif [[ $jobType == "c" ]]; then
		currentStatus=$(glite-wms-job-status -i $jobID 2>&1 | grep "Current Status" -m 1 | cut -d":" -f 2 | tr -d ' ')
	fi

	timeNow=$(date +"%Y%m%d %T")
        # get time difference
        Time "$startTime" "$timeNow"
        if [[ $diff -gt 7200 ]]; then # 2 hours 
                # check if scheduled and if yes, cancel and resubmit
		if [[ $currentStatus == "Scheduled" ]]; then
			CancelAndResubmit
			if [[ $? != 0 ]]; then
				# if submit failed, try one more time
				CancelAndResubmit
			fi
		fi
	fi

	# check the status
	if [[ $currentStatus == "Running" ]]; then
		echo "Job is Running, wait for it to finish"
		sleep 100
	elif [[ $currentStatus == "Done(Success)" ]]; then
		echo "Done, get the output"
		getOutput="true"
		run="false"
	elif [[ $currentStatus == "Aborted" ]]; then
		#check again
		if [[ $jobType == "s" ]]; then                                                             
	                currentStatus=$(glite-wms-job-status -i $jobID 2>/dev/null | grep "Current Status" | cut -d":" -f 2 | tr -d ' ')
	        elif [[ $jobType == "c" ]]; then                                                           
        	        currentStatus=$(glite-wms-job-status -i $jobID 2>/dev/null | grep "Current Status" -m 1 | cut -d":" -f 2 | tr -d ' ')
        	fi
		if [[ $currentStatus == "Aborted" ]]; then 
			echo "Job Aborted"
			run="false"
			exit 5
	fi
	elif [[ $currentStatus == "Cancelled" ||  $currentStatus == "Done(Exit Code !=0)"  || $currentStatus == "Cleared" ]]; then
		echo "Job failed and will be resubmitted"
		if [[ $sameJobRuns -lt 20 ]]; then                                      
                    	CancelAndResubmit
			if [[ $? != 0 ]]; then
                                # if submit failed, try one more time
                                CancelAndResubmit
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
	else
		error=$(glite-wms-job-status -i $jobID 2>&1 | grep "Unable to find" | grep "$jobID")
		if [[ ! -z $error ]]; then
			echo "Something is wrong with the grid"
                       	exit 4

		fi
		sleep 60
	fi
done

################################################################################
#                                                                              #
#                          Get the output                                      #
#                                                                              #
################################################################################

if [[ $getOutput == "true" ]]; then
	
	export LFC_HOST=`lcg-infosites --vo see lfc`
	export LCG_CATALOG_TYPE=lfc
	export LCG_GFAL_VO=see
	
	mkdir Output_$timestamp
	outputFolder="Output_$timestamp"

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
