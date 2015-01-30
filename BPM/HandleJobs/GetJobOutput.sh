#!/bin/bash

# this script lists the files that the parametric jobs have uploaded to the grid
# if the correct number of files are uploaded then no need to resubmit any jobs
# if not then some jobs failed and need to be resubmitted in order for the missing files to be generated

# first argument is the number of jobs running
# second argument is the timestamp of the folder everything is saved in
# third argument is the option the user has selected to run

jobsNum=${1}
timestamp=${2}
option=${3}

lcg-ls lfn:/grid/see/`whoami`/BPM_$timestamp > listoutput

for i in `seq $jobsNum`; do
	case $option in
	
	1|4|5)
		found=$(grep "output$i.tar.gz" listoutput)
	;;
	2|3) 
		found=$(grep "phyl$i.tar.gz" listoutput)
	;;
	esac
	if [[ -z $found ]]; then
		# not found
		echo "$i" >> nodesToResubmit
	fi
done
rm listoutput
