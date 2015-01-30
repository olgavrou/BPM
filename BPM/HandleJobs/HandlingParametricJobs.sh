#!/bin/bash  

# This script hadles parametric jobs. It takes the jobID and the job jdl file as arguments.
# When at least one job runs and finishes successfully, then if there are jobs still scheduled
# it cancels and resubmits them.
# When all jobs are done, it calls the GetJobOutput script which in turn generates a "nodesToResubmit" file
# If some jobs failed it resubmits them
# It loops until all jobshave finished successfully or an error occurs
#TODO: rare "jobs are waiting" bug

################## functions ##################################################

Handle (){
	jobID=${1}
	jdl=${2}
	check="true"
 	fallAsleep=0
	hasItRun="false"
	jobForked="false"
	sameJobRuns=0	
	while $check; do
	# get info about the job status
	
		glite-wms-parametric-job-status -n -i $jobID > "$statusLog" 2>/dev/null
		
		numOfJobs=$(glite-wms-job-status -i $jobID 2>/dev/null | grep "Current Status" -c )
	        numOfJobs=$((numOfJobs -1))
		echo "number of jobs: $numOfJobs"

		submitted=$(./GetSeperateStatuses.sh "Submitted" $statusLog); echo "submitted: $submitted"
		ready=$(./GetSeperateStatuses.sh "Ready" $statusLog); echo "ready: $ready"
		running=$(./GetSeperateStatuses.sh "Running" $statusLog); echo "running: $running"
		aborted=$(./GetSeperateStatuses.sh "Aborted" $statusLog); echo "aborted: $aborted"
		success=$(./GetSeperateStatuses.sh "Success" $statusLog); echo "success: $success"
		exited=$(./GetSeperateStatuses.sh "Exit" $statusLog); echo "exited: $exited"
		cleared=$(./GetSeperateStatuses.sh "Cleared" $statusLog); echo "cleared: $cleared"
		cancelled=$(./GetSeperateStatuses.sh "Cancelled" $statusLog); echo "cancelled: $cancelled"
		scheduled=$(./GetSeperateStatuses.sh "Scheduled" $statusLog); echo "scheduled: $scheduled"
		echo ""		
			
		if [[ $((submitted + ready + scheduled + cancelled)) == $numOfJobs ]]; then
			echo "Waiting for the jobs to start running..."
			if [[ $fallAsleep -lt 10 ]]; then
				echo "......."
				let fallAsleep++
				sleep 60
				continue
			else
				echo "Jobs are stuck, and will be canceled and resubmitted"
				fallAsleep=0
				if [[ $sameJobRuns -lt 3 ]]; then
                		        echo "y" | glite-wms-job-cancel -i $jobID >> /dev/null 2>&1
                		        rm "$jobID"
                		        glite-wms-job-submit -o "$jobID" -a "$jdl" 2 > /dev/null
                		        let sameJobRuns++
					continue
               			 else
                        		echo "Something is wrong with the grid"
                        		return 1
                		fi 
			fi
		
		elif [[ $aborted != "0" ]]; then
			echo "Jobs have been aborted or jobid is old. Get a proxy and resubmit."
			return 2
		
		elif [[ $((submitted + ready + running + aborted + success + exited + cleared + cancelled + scheduled)) == "0" ]]; then
                       if [[ $fallAsleep -lt 20 ]]; then
                               let fallAsleep++
                               echo "......."
                               sleep 10
                               continue
                       else
				currentStatus=$(glite-wms-job-status -i $jobID 2>/dev/null | grep "Current Status" -m 1 | cut -d":" -f 2 | tr -d ' ') 
				if [[ $currentStatus == "Done(Success)" ]]; then
					echo "Jobs are done"
					return 0
				elif [[ $currentStatus != "Aborted" && $currentStatus != "Cancelled" && $currentStatus != "Cleared" && $currentStatus != "Done(Exit Code" ]]; then
					fallAsleep=0
					continue
				else
                                	echo "Jobs have been aborted or jobid is old. Get a proxy and resubmit."
                                	return 2
				fi
                       fi
		
		elif [[ $running != "0" && $hasItRun == "false" ]]; then
			hasItRun="true"
			echo "Jobs are running..."
		elif [[ $running == "0" &&  $hasItRun == "true"  ]]; then
			echo "Running jobs have terminated."
			
			if [[ $jobForked == "false" ]]; then
				if [[ $exited != "0" ]]; then
					awk '/Exit/{if(NF>12){print $13}}' $statusLog | cut -d "[" -f 2 | cut -d "]" -f 1 > nodesToResubmit
				fi
				
				if [[ $ready != "0" ]]; then
					awk '/Ready/{if(NF>10){print $11}}' $statusLog | cut -d "[" -f 2 | cut -d "]" -f 1 >> nodesToResubmit
				fi

				if [[ $submitted != "0" ]]; then
					awk '/Ready/{if(NF>10){print $11}}' $statusLog | cut -d "[" -f 2 | cut -d "]" -f 1 >> nodesToResubmit
				fi

				if [[ $scheduled != "0" ]]; then
                                        awk '/Scheduled/{if(NF>10){print $11}}' $statusLog | cut -d "[" -f 2 | cut -d "]" -f 1 >> nodesToResubmit
                                        scheduledJobs=$scheduled
                                        while [[ $scheduledJobs != $(( cancelled + cleared )) ]]; do
                                                echo "Canceling jobs that are stuck..."
                                                echo "y" | glite-wms-parametric-job-status -i $jobID >> /dev/null 2>&1
                                                sleep 100
                                                glite-wms-parametric-job-status -n -i $jobID > "$statusLog" 2>/dev/null
                                                cancelled=$(./GetSeperateStatuses.sh "Cancelled" $statusLog); echo "cancelled: $cancelled"
						cleared=$(./GetSeperateStatuses.sh "Cleared" $statusLog); echo "cleared: $cleared"
                                        done

                                fi

				ishere=$(ls | grep "nodesToResubmit")
				isEmpty=$(find . -empty -name "nodesToResubmit")
				if [[ ! -z $ishere  && -z $isEmpty ]]; then
					echo "Some Jobs failed and will need to be resubmitted"
					jobForked="true"
				else
					echo "All jobs terminated successfully, no need to resubmit them"
					rm nodesToResubmit
				fi
			fi	

			if [[ $((cancelled + success + cleared + exited)) == $numOfJobs  ]]; then
				if [[ $jobForked == "false" ]]; then
					return 0
				else
					return 3
				fi
			fi
		#else
		#	echo "Unknown error"
		#	exit 6
		fi

		echo "sleep 100 seconds"
		sleep 100
		echo ""
	done
}


SubmitNewJob(){
	jobid=${1}
	jobjdl=${2}
	numberOfJobs=${3}

	echo "Parameters = {" > newPar
	# the flag is for us to know if we are reading the first line or not, so the "," are placed accordingly in the jdl file for the parameters
	flag=0
	while read line; do
		if [[ $flag == 0 ]]; then
			awk '{print $0,"'$line'"}' newPar > newParTemp
		else
			awk '{print $0,",'$line'"}' newPar > newParTemp
		fi
		mv newParTemp newPar
		flag=1
	done < nodesToResubmit
	awk '{print $0,"};"}' newPar > newParTemp
	mv newParTemp newPar
	rm nodesToResubmit
	awk '{if($0 !~ /Parameter/){print;}}' $jobjdl >> jdlTemp
        cat jdlTemp newPar > "job$numberOfJobs.jdl"
        rm jdlTemp newPar
	glite-wms-job-submit -o "$jobid$numberOfJobs" -a "job$numberOfJobs.jdl" 2>/dev/null
	echo "......."
	sleep 60	
}
##################################################################################################################################################################
jobID=${1}
jdl=${2}
timestamp=${3}
option=${4}

run="true"
# jobNum keeps the number of times jobs have been resubmitted, in order to make new jobids and jdls
jobNum=0
statusLog="status_log""$jobID"
# timesResubmited keeps track of how many times I needed to try and resubmit the jobs with cancelled and 
# not successful states (forked jobs). max 4 times
timesResubmited=0
while $run; do
	if [[ $jobNum == 0 ]]; then
		# first job
		jobID=${1}
		jdl=${2}
		# the first job to be submitted will tell us the number of jobs in total
		totalJobNum=$(glite-wms-job-status -i $jobID 2>/dev/null | grep "Current Status" -c )
                totalJobNum=$((totalJobNum -1))
	else
		echo "some other job: $jobNum"
		jobID="$jobID$jobNum"
		jdl="job$jobNum.jdl"
	fi
	Handle $jobID $jdl
	returnStatus=$?
	if [[ $returnStatus == 1 ]]; then
		exit 4
	elif [[ $returnStatus == 2 ]]; then
		exit 5
	elif [[ $returnStatus == 3 ]]; then
		if [[ $timesResubmited -lt 5 ]]; then
			let jobNum++
			SubmitNewJob $jobID $jdl $jobNum
		else
			exit 4
		fi
	elif [[ $returnStatus == 0 ]]; then
		touch nodesToResubmit 
		./GetJobOutput.sh $totalJobNum $timestamp $option
		isEmpty=$(find . -empty -name "nodesToResubmit")
              	if [[ -z $isEmpty ]]; then
    			let jobNum++
			SubmitNewJob $jobID $jdl $jobNum
             	else
                  	# no need to resubmit jobs
                        rm nodesToResubmit
			run="false"
              	fi
	fi
done

