#!/bin/bash

# This script is called from the HandlingParametricJobs script. Returns the number of jobs that are
# currently in the statusOf status state.

statusOf=${1}
statusLog=${2}

if [[ $statusOf == "Exit"  ]]
then
	howMany=$(awk '/'$statusOf'/{if(NF>12){print $13}}' "$statusLog" | cut -d "[" -f 2 | cut -d "]" -f 1 | awk 'BEGIN{FS=","}{print NF}')
else
	howMany=$(awk '/'$statusOf'/{if(NF>10){print $11}}' "$statusLog" | cut -d "[" -f 2 | cut -d "]" -f 1 | awk 'BEGIN{FS=","}{print NF}')
fi

if [[ -z $howMany ]]
then
	echo 0
else
	echo "$howMany"
fi

