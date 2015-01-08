#!/bin/bash -x

# first argument is the job id

jobID=${1}

glite-wms-job-status -i $jobID > status$jobID

waiting=$(grep "Waiting" -c status$jobID)
if [[ $waiting == 1 ]]; then
	echo "head is waiting"
	grep "Status info for the Job" status$jobID > jobIDs
	i=1
	while read line; do
		echo "$line" | cut -d" " -f 7 > jobid
 		glite-wms-job-output -i jobid --dir jobid$i
		i=$((i+1))
	done < jobIDs
	
	i=$((i-1))

	for i in `seq $i`
	do
		subdir=$(ls jobid$i )
		outLocation=jobid$i/$subdir
		cd $outLocation
		ls | grep ".err" > MyNode
                whichNode=$(cat MyNode | cut -d"." -f 1 | cut -d"d" -f 2)
		problemOcc=$(grep -R "PROBLEM OCCURED" *)
		if [[ -z $problemOcc ]]; then
			echo "all good in node $whichNode"
		else
			echo "$whichNode" >> ../../resub
		fi
		#unzip out.zip
		#cp output.abc ../../outputfile/out$whichNode.abc
		rm MyNode
		cd -
	done
	rm -rf jobid*	
else # all is good
	glite-wms-job-output -i $jobID --dir jobOut
        
        subdir=$(ls jobOut)
        outLocation=jobOut/$subdir

        # unzip and get the output
        cd $outLocation
	ls | grep "Node_" > MyNodesT
	awk '{for(i=1;i<=NF;i++){print $i;}}' MyNodesT >> MyNodes
	rm MyNodesT
        while read line;  do
                #unzip $line/out.zip
		whichNode=$(echo "$line" | cut -d"_" -f 2)
		problemOcc=$(grep -R "PROBLEM OCCURED" $line)
		if [[ -z $problemOcc ]]; then
                        echo "all good in node $whichNode"
                else
                        echo "$whichNode" >> ../../resub
                fi
                #mv output.abc ../../outputfile/out$whichNode.abc
        done < MyNodes
	rm MyNodes

        cd -

	rm -rf jobOut
fi
