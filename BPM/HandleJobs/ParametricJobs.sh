#!/bin/bash 

#-- ParametricJobs.sh --------------------------------------------------------------
#
# This script handles a number of parametric jobs.
# It follows their status, resubmits the scheduled ones after a time period.
# It checks to see if the jobs where completed successfully, 
# and if not, resubmits them.
#
# Arguments
# 1. Number of parametric jobs
# 2. The program instances timestamp
# 3. The selected option
# 4. The total number of submitted jobs
#
#----------------------------------------------------------------------------------------


################################################################################
#                                                                              #
#                               functions                                      #
#                                                                              #
################################################################################

Handle(){
        jobID=jobID${1}
        jdl=job${1}.jdl
        jobNumber=${1}
   
       	# get info about the job status
     	glite-wms-job-status -i $jobID > T$statusLog 2>/dev/null
 	numOfJobs=$(grep "Current Status" -c T$statusLog)
    	numOfJobs=$((numOfJobs -1))
      	echo "number of jobs: $numOfJobs"

     	# get rid of the header
     	awk '{if(NR > 9){print}}' T$statusLog > "$statusLog"
	# get the number of jobs in each status
       	submitted=$(grep "Current Status:     Submitted" -c $statusLog); echo "submitted: $submitted"
       	ready=$(grep "Current Status:     Ready" -c $statusLog); echo "ready: $ready"
       	running=$(grep "Current Status:     Running" -c $statusLog); echo "running: $running"
       	aborted=$(grep "Current Status:     Aborted" -c $statusLog); echo "aborted: $aborted"
       	success=$(grep "Current Status:     Done(Success)" -c $statusLog); echo "success: $success"
       	exited=$(grep "Current Status:     Done(Exit" -c $statusLog); echo "exited: $exited"
       	cleared=$(grep "Current Status:     Cleared" -c $statusLog); echo "cleared: $cleared"
      	cancelled=$(grep "Current Status:     Cancelled" -c $statusLog); echo "cancelled: $cancelled"
       	scheduled=$(grep "Current Status:     Scheduled" -c $statusLog); echo "scheduled: $scheduled"
	totalRunning=$((totalRunning + running))
        totalScheduled=$((totalScheduled + scheduled))
	totalReady=$(( totalReady + ready))
	
       	echo ""
      	if [[ $numOfJobs == -1 ]]; then
           	echo "Nothing is wrong. The grid just doesn't want to give a report some times"                                      
               	currentStatus=$(glite-wms-job-status -i $jobID 2>/dev/null | grep "Current Status" -m 1 | cut -d":" -f 2 | tr -d ' ')
             	if [[ $currentStatus == "Done(Success)" ]]; then
               		echo "Jobs are done"
                   	return 0
		else
			return 3
              	fi
                       
    	elif [[ $running != "0" ]]; then
             	echo "Jobs are running..."
             	return 3
     	elif [[ $running == "0" ]] && [[ $success != "0" || $exited != "0" || $cleared != "0" || $cancelled != "0" || $aborted != "0" ]]; then
            	echo "Running jobs have terminated."
            	return 0
      	elif [[ $scheduled != "0" || $submitted != "0" || $ready != "0" ]]; then
		echo "Jobs are scheduled"
		return 4
	fi

      	echo ""
}

ResubmittableNodes(){
	resub=${1}
	activeNodes=();
	matrixLength=${#jobIDMatrix[@]}

	for j in `seq  $matrixLength`; do
                jid=${jobIDMatrix[$((j -1))]}
               	id=$(grep "^https" jobID$jid)
               	glite-wms-job-status -v 2 $id > $statusLog 2>&1
               	activeNodes=(${activeNodes[@]} `egrep "Current Status:    | Node Name:          Node_" $statusLog | awk 'BEGIN {RS="    Current Status:    "; FS="\n    Node Name:          Node_"; ORS="";}/Running/{print $2}'`)
		activeNodes=(${activeNodes[@]} `egrep "Current Status:    | Node Name:          Node_" $statusLog | awk 'BEGIN {RS="    Current Status:    "; FS="\n    Node Name:          Node_"; ORS="";}/Scheduled/{print $2}'`)
        done
	# investigate which of the resub nodes are active
	mv $resub tempresub
	matrixL=${#activeNodes[@]}
	for j in `seq $matrixL`; do
		grep -v -w "${activeNodes[$((j -1))]}" tempresub > temp
		mv temp tempresub
	done
	cp tempresub $resub

	# investigate which of the jobs have completed already
	while read line; do
		#h lcg-ls lfn:/grid/see/`whoami`/BPM_$timestamp/output$line.tar.gz > $statusLog 2>&1
		lcg-ls lfn:/grid/see/`whoami`/BPM_$timestamp/phyl$line.tar.gz > $statusLog 2>&1
		if [[ $? == 0 ]]; then
			echo "job already ran"
			grep -v -w "$line" tempresub > temp
			mv temp tempresub
			continue
		fi
		lcg-ls lfn:/grid/see/`whoami`/BPM_$timestamp/phyl$line.tar.gz > $statusLog 2>&1
		if [[ $? == 0 ]]; then
			echo "job already ran"
			grep -v -w "$line" tempresub > temp
			mv temp tempresub
		fi
		done < $resub
		mv tempresub $resub
	# resub holds the nodes that are ok to be resubmitted
}

SubmitNewJobs(){
        # where any jobs found?
        jdl=${1}

        if [[ -s nodesToResubmit ]]; then
		if [[ `grep "." -c nodesToResubmit` -gt 50 ]]; then
			split -l 50 nodesToResubmit	
		else
			mv nodesToResubmit xaa
		fi
		files=(`ls | grep  xa`)
		numF=${#files[@]}
		for j in `seq $numF`; do
			file=${files[$((j-1))]}	
                	# some jobs failed and will be resubmitted
                	echo "there are some jobs that need resubmitting that where not successfull"
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
                	done < $file
                	awk '{print $0,"};"}' newPar > newParTemp
                	mv newParTemp newPar
                
                	awk '{if($0 !~ /Parameter/){print}}' $jdl > jdlTemp
			matrixLength=${#jobIDMatrix[@]}
                	cat jdlTemp newPar > job$((matrixLength + 1 )).jdl
                	rm -f jdlTemp newPar
                	cd - > /dev/null
                	glite-wms-job-submit -o "$sf/jobID$((matrixLength +1 ))" -a "$sf/job$((matrixLength + 1)).jdl" > "$sf/$statusLog" 2>&1
                	cd - > /dev/null
                	error=$(grep "Error -" $statusLog)
                	if [[ -z $error ]]; then
                	        echo "New job submitted"
                	        jobIDMatrix=(${jobIDMatrix[@]} $((matrixLength + 1)))
                	        matrixLength=$((matrixLength + 1))
                	else
                	        echo ""
                	        # was not submitted
                	        # this job needs to be checked again
                	        rm -f jobID$((matrixLength + 1 ))
                	        rm -f job$((matrixLength + 1)).jdl
                	        return 1;
                	fi
                	sleep 10
		done
		rm -f xa*
        else
                echo "all jobs that ran where successfull"
        fi
}

CancelScheduled(){
	# canceles and resubmits jobs that are scheduled
	# before resubmitting every job, check to see if it has already run or it is running

        jobID=jobID${1}
        jdl=job${1}.jdl
        statusLog=job_statusLog
	echo ""
        echo "Canceling jobs that are stuck..."
        echo "y" | glite-wms-parametric-job-status -i $jobID > $statusLog 2>&1
        sleep 10
        awk '/Parameters = {/{print;}' $statusLog | cut -d"{" -f2 | cut -d"}" -f1 | awk -F "," '{for(i=1;i<=NF;i++){print $i}}' | sed 's/"//g' > nodesToResubmit
	
       	notCancelled="true"
    	cancelCount=0
        while $notCancelled && [[ $cancelCount -lt 5 ]]; do
                echo "Waiting for jobs to be cancelled"
                cancelCount=$(( cancelCount + 1))
		sleep 60
		echo ""
       		echo "y" | glite-wms-parametric-job-status -i $jobID > $statusLog 2>&1
             	glite-wms-job-status -i $jobID > T$statusLog 2>/dev/null
             	awk '{if(NR > 9){print}}' T$statusLog > "$statusLog"
           	scheduled=$(grep "Current Status:     Scheduled" -c $statusLog); echo "scheduled: $scheduled"
		totalJobs=$(grep "Current Status" -c T$statusLog) # if zero, the grid is not reporting
        	if [[ $scheduled == "0" && $totalJobs != "0" ]]; then
                    	notCancelled="false"
         	fi
      	done
	echo "......."

	ResubmittableNodes nodesToResubmit # returns nodesToResubmit that are ok to resubmit (nor running or already done)
        # nodesToResubmit is cleared now

        # make new jdl and submit the new job
        SubmitNewJobs $jdl
}


CancelAllScheduledJobs(){
	# every 12 hours, all scheduled jobs are cancelled and resubmitted
	matrixLength=${#jobIDMatrix[@]}
	echo ""
	echo "12 hours have gone by. All the parametric jobs will be checked"
	echo "Jobs still in scheduled state will be cancelled and resubmitted"
	echo ""
	
	for j in `seq  $matrixLength`; do
        	jid=${jobIDMatrix[$((j -1))]}
        	if [[ -z `echo "${doneMatrix[@]}" | grep -w "$jid"` ]]; then
                	glite-wms-job-status -i jobID$jid > T$statusLog 2>&1
			# get rid of the header
        		awk '{if(NR > 9){print}}' T$statusLog > "$statusLog"
                	scheduled=$(grep "Current Status:     Scheduled" -c $statusLog); echo "scheduled: $scheduled"
                	
                	if [[ $scheduled != "0" ]]; then
				echo "jID: $i there are some jobs that need resubmitting that where scheduled"
                        	
                        	CancelScheduled $jid
                	else
				echo "jID: $i no jobs scheduled"
			fi
        	fi
	done

}


CheckSuccessOfJobs(){
	# when a job is done, check if the submitted jobs that
	# terminated and weren't cancelled are successful
	# if not then resubmit the failed jobs

        jid=${1}
        jdl=job$jid.jdl
	echo "Check to see if jobs where successfull"

	matrixLength=${#jobIDMatrix[@]}
	touch nodesToResubmit	

       	id=$(grep "^https" jobID$jid)
      	glite-wms-job-status -v 2 $id > $statusLog 2>&1
       	egrep "Current Status:    | Node Name:          Node_" $statusLog | awk 'BEGIN {RS="    Current Status:    "; FS="\n    Node Name:          Node_"; ORS="";} /Done\(Success\)/ {print $2}' >> nodesToResubmit

	ResubmittableNodes nodesToResubmit # returns nodesToResubmit that are ok to resubmit (nor running or already done)
        # nodesToResubmit is cleared now
	
	SubmitNewJobs $jdl 
	return $?
}

Time(){
# get the time difference of the two timestamps
	timestamp1=${1}
	timestamp2=${2}
        t=$(date -d "$timestamp1" +%s)
        t1=$(date -d "$timestamp2" +%s)
        diff=$(expr $t1 - $t)

}

AreAllJobsDone(){
	lcg-ls lfn:/grid/see/`whoami`/BPM_$timestamp > listoutput
	case $option in
	1|4|5)
 		#h areDone=$(grep "output" -c listoutput)
		areDone=$(grep "phyl" -c listoutput)
       	;;
	2|3)
		areDone=$(grep "phyl" -c listoutput)
	;;
	esac

	if [[ $areDone == $totalNumOfJobs ]]; then
		echo "All jobs have finished successfuly"
                return 0    
      	else
		return 1
	fi

}

ResubmitFailedJobs(){
	# this script is called when all the jobs are done
	# checks to see if they were successfull and if they uploaded what was needed
	# if not, then resubmits the ones that failed
	# called right after AreAllJobsDone, so listoutput is updated
	touch nodesToResubmit
	for j in `seq $totalNumOfJobs`; do
        	#h found=$(grep "output$j.tar.gz" listoutput || grep "phyl$j.tar.gz" listoutput)
		found=$(grep "phyl$j.tar.gz" listoutput || grep "phyl$j.tar.gz" listoutput)
        	if [[ -z $found ]]; then
        	        echo "$j" >> nodesToResubmit
        	fi
	done
	matrixLength=${#jobIDMatrix[@]}

	SubmitNewJobs job$((matrixLength - 1)).jdl
        return $?
}

AreTheyAllRunning(){
	# this function checks to see if all the jobs are either completed or running
	# and submits those that aren't
	touch nodesToResubmit
	for j in `seq $totalNumOfJobs`; do
		echo "$j" >> nodesToResubmit
	done
	ResubmittableNodes nodesToResubmit # returns nodesToResubmit that are ok to resubmit (nor running or already done)
        # nodesToResubmit is cleared now
	matrixLength=${#jobIDMatrix[@]}
        SubmitNewJobs job$((matrixLength - 1)).jdl
}

################################################################################
#                                                                              #
#                    Control the main flow of jobs                             #
#                                                                              #
################################################################################

jobMatrixLength=${1} # just numbers, the convention is jobID# and job#.jdl
timestamp=${2}
option=${3}
totalNumOfJobs=${4}

jobIDMatrix=()
for i in `seq $jobMatrixLength`; do
        jobIDMatrix=(${jobIDMatrix[@]} $i)
done
doneMatrix=() # matrix that hold the jobs that are completed, so they won't be tested anymore

sf="SessionFolder_$timestamp"
# go to session folder
cd SessionFolder_$timestamp
run="true"

timeStartScheduled=$(date +"%Y%m%d %T")
timeStartRunCheck=$(date +"%Y%m%d %T")

statusLog=job_statusLog
mkdir TheOutput

# run until all the parametric jobs are done
while $run; do

	matrixLength=${#jobIDMatrix[@]}
        doneMatrixLength=${#doneMatrix[@]}

	timeNow=$(date +"%Y%m%d %T")
	# get time difference
	Time "$timeStartScheduled" "$timeNow"
	
	activeParametricJobs=$((matrixLength - doneMatrixLength))

	if [[ $diff -gt 43200 ]] || [[ $activeParametricJobs -lt 4 && $diff -gt 7200 ]]; then # 12 hours or 2 hours if under 4 active parametric jobs
		# cancel all scheduled jobs
		CancelAllScheduledJobs 
		# reset the timer
		timeStartScheduled=$(date +"%Y%m%d %T")

		# are they all done maybe?
		AreAllJobsDone
		if [[ $? == 0 ]]; then
			# all jobs have finished successfully
			# can terminate possible running jobs and continue	
			run="false"
			continue
		fi
	fi
	
	Time "$timeStartRunCheck" "$timeNow"
	if [[ $diff -gt 14400 ]]; then # 4 hours
		# check to see if any jobs where missed and are not running
		AreTheyAllRunning
		# reset the timer
		timeStartRunCheck=$(date +"%Y%m%d %T")
	fi	

	if [[ $matrixLength == $doneMatrixLength ]]; then
		# all jobs are done
		AreAllJobsDone
                if [[ $? == 1 ]]; then
			ResubmitFailedJobs
			continue
		else
                        run="false"
                fi

		continue
	else
		totalRunning=0
		totalScheduled=0
		totalReady=0
		for i in `seq  $matrixLength`; do
        		jID=${jobIDMatrix[$((i -1))]}
			if [[ -z `echo "${doneMatrix[@]}" | grep -w "$jID"` ]]; then
				sleep 10
				echo "jID: $jID"
				Handle $jID
				returnStatus=$?
				if [[ $returnStatus == 0 ]]; then
					# jobs are done
					 
					if [[ $scheduled != "0" ]]; then
						CancelScheduled $jID
                		        fi
					CheckSuccessOfJobs $jID
					if [ $? != 1 ]; then
						# the folder was accessed and so I can remove this job from the ones to be checked
						# by putting jobid in done matrix
						doneMatrix=(${doneMatrix[@]} $jID)
					fi

					# make folder for the output to be stored
				        #if [[ -d "TheOutput/o1" ]]; then
                			#	i=1
                			#	while [[ -d "TheOutput/o$i" ]]; do
                        		#		let i++
                			#	done
                			#	outDir="TheOutput/o$i"
        				#else
                			#	outDir="TheOutput/o1"
        				#fi
					#glite-wms-job-output -i jobID$jID --dir $outDir

				elif [[ $returnStatus == 2 ]]; then
					exit 5
				elif [[ $returnStatus == 3 || $returnStatus == 4 ]]; then
					continue
				fi
			fi
		done
		echo "total running: $totalRunning"
		echo "total scheduled: $totalScheduled"	
		echo "total ready: $totalReady"	
		echo "sleep 100 seconds"
		sleep 100
	fi
done

# the some jobs might still be running
# cancel all jobs that might be running

matrixLength=${#jobIDMatrix[@]}
for i in `seq  $matrixLength`; do
	jID=${jobIDMatrix[$((i -1))]}
	echo "y" | glite-wms-job-cancel -i jobID$jID > /dev/null 2>&1
done

# go back to the main folder
cd ../
