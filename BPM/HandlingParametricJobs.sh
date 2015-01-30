#!/bin/bash  

# this script takes as an argument the job id file and the jdl file
# if jobs are running it waits untill they finish
# if after they finish there are still scheduled jobs it cancels and resubmits them
# if jobs are not running it sleeps for 4 loops and then cancels and resubmits 3 times until they run
# otherwise it exits

#TODO: needs some tuning
#DECOLORIZE='eval sed "s,\[;031m,,g" | sed "s,\[0m,,g" | awk "{printf(\"%s\n\",\$0)}" '
#HOWMANY='eval awk "/"$what"/{if(NF>10){print \$11}}" | cut -d "[" -f 2 | cut -d "]" -f 1 | awk "BEGIN{FS=\",\"}{print NF}" '
################## functions ##################################################

Handle (){
	jobID=${1}
	jdl=${2}
	check="true"
 	fallAsleep=0
	hasItRun="false"
	jobForked="false"
	sameJobRuns=0	
	while $check
	do
	# get info about the job status
	
		glite-wms-parametric-job-status -n -i $jobID > "$statusLog"
		
		numOfJobs=$(glite-wms-job-status -i $jobID | grep "Current Status" -c )
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
			
			
		if [[ $((submitted + ready + scheduled + cancelled)) == $numOfJobs ]]
		then
			if [[ $fallAsleep -lt 4 ]]
			then
				echo "fall asleep"
				fallAsleep=$((fallAsleep + 1))
				sleep 60
				continue;
			else
				echo "jobs are stuck, cancel and resubmit"
				fallAsleep=0
				if [[ $sameJobRuns -lt 3 ]]
               			then
                		        echo "y" | glite-wms-job-cancel -i $jobID
                		        rm "$jobID"
                		        glite-wms-job-submit -o "$jobID" -a "$jdl"
                		        sameJobRuns=$((sameJobRuns + 1))
					echo "cancelled and resubmitted"
					continue
               			 else
                        		echo "Something is wrong with the grid"
                        		return 1
                		fi 
			fi
		fi
	
		if [[ $aborted != "0" || $((submitted + ready + running + aborted + success + exited + cleared + cancelled + scheduled)) == "0" ]]
		then
			echo "Jobs have been aborted or jobid is old. Get a proxy and resubmit."
			return 2
		fi
		
		if [[ $running != "0" && $hasItRun == "false" ]]
		then
			hasItRun="true"
			echo "Some jobs are running. Wait until they finish and then check what is going on"
		elif [[ $running == "0" &&  $hasItRun == "true"  ]] 
		then
			echo "running jobs have terminated. Check and see if there are still scheduled or exited with failed status"
		echo "$jobForked"	
			if [[ $((cancelled + success + cleared)) == $numOfJobs  ]]
			then
				echo "the jobs have terminated successfully"
				if [[ $jobForked == "false" ]]
				then
					echo "this job did not cancel and resubmit"
					return 0
				else
					echo "this job needs to submit the new job"
					return 3
				fi
			elif [[ $ready != "0" ]]
			then
				echo "Some jobs have finished while others are in ready state and can not be canceled"
				# what can I do here? can the be canceled? do I resubmit the whole thing from the begining?
			elif [[ $jobForked == "false" ]]
			then
				echo "some jobs need to be resubmitted"
				echo "Cancel some jobs and resubmit them."
			#TODO: need to resubmit the exited status also duhhhhhhh
			# cancel until the jobs are really cancelled
				scheduledJobs=$scheduled
				while [[ $scheduledJobs != $cancelled ]]
				do
					echo "cancell not done correctly"
					echo "Scheduled: $scheduledJobs , cancelled: $cancelled"
                			echo "y" | glite-wms-parametric-job-status -i $jobID > whichNeedCancellingLog
					sleep 100
					glite-wms-parametric-job-status -n -i $jobID > "$statusLog"
					cancelled=$(./GetSeperateStatuses.sh "Cancelled" $statusLog); echo "cancelled: $cancelled"
				done

                		awk '/Parameters = {/{print;}' whichNeedCancellingLog > newParTemp
                		jobNum=$((jobNum + 1))
                		awk '{if($0 !~ /Parameter/){print;}}' $jdl >> jdlTemp
				cat jdlTemp newParTemp > "job$jobNum.jdl"
				rm jdlTemp newParTemp whichNeedCancellingLog
				sleep 5
                		glite-wms-job-submit -o "$jobID$jobNum" -a "job$jobNum.jdl"
						
				jobForked="true"
				
				continue # this script will return when this jobID is finished. Then the next one will be submitted
			fi
		fi
		echo "sleep 1 min"
		sleep 100
	done
}

##################################################################################################################################################################
jobID=${1}
jdl=${2}
run="true"
jobNum=0
statusLog="status_log""$jobID"
jobMatrix=($jobID)

while $run
do
	if [[ $jobNum == 0 ]]
	then
		echo "first job"
		jobID=${1}
		jdl=${2}
		# the first job to be submitted will tell us the number of jobs in total
		totalJobNum=$(glite-wms-job-status -i $jobID | grep "Current Status" -c )
                totalJobNum=$((totalJobNum -1))
	else
		echo "some other job: $jobNum"
		jobID="$jobID$jobNum"
		jdl="job$jobNum.jdl"
		jobMatrix=(${jobMatrix[@]} $jobID)
	fi
	Handle $jobID $jdl
	returnStatus=$?
	if [[ $returnStatus == 1 ]]
	then
		echo "$i job can't run"
		run="false"
		#later I could maybe make it run on a different WN
	elif [[ $returnStatus == 2 ]]
	then
		echo "get proxy again"
		run="false"
		exit 6
		#don't know exactly what to do if this happends. 
	elif [[ $returnStatus == 3 ]]
	then
		echo "submit new job"
	elif [[ $returnStatus == 0 ]]
	then
		echo "all done"
		run="false"
	fi
done

#date >> hello


touch resub
matrixLength=${#jobMatrix[@]}
for i in `seq  $matrixLength`
do
        echo "${jobMatrix[$((i -1))]}"
	./GetJobOutput.sh ${jobMatrix[$((i -1))]}	
done

#outFiles=$(ls outputfile/ | wc -l )
#if [[ $outFiles != $totalJobNum ]]; then
#	echo "Output Files not the same as the number of jobs"
#	exit 3 
#fi
