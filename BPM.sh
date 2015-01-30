#!/bin/bash

# This script is where the application starts
# The input is the Input.txt file

input=${1}

########## Parse the input to get the details ##########

query=`awk '/query_file/{print $2;}' $input`
geneMap=`awk '/gene_map/{print $2;}' $input`
rawDatabase=`awk '/raw_database/{print $2;}' $input`
readyDatabase=`awk '/ready_database/{print $2;}' $input`
option=`awk '/option/{print $2;}' $input`
email=`awk '/email/{print $2;}' $input`
########################################################
#### functions ####
Exit(){
	status=${1}
	case $status in
	1) echo "The Input.txt file is not correct" > Report.txt
	;;
	2) echo "The database file wasn't created" > Report.txt
	;;
	3) echo "The files needed for the jobs to run where not able to upload" > Report.txt
	;;
	4) echo "The parametric jobs have been resubmitted 3 times withouth them beeing able to run" > Report.txt
	   echo "The grid is too busy at the moment" >> Report.txt
	;;
	5) echo "The parametric jobs can't run. Please check for valid proxy" > Report.txt
	;;
	6) echo "Unknown error occurred. Please try again." > Report.txt
	;; 
	0) 
	echo "Job is done and cleanup will be running on background. A message will be printed when it is done" >> Report.txt
        echo "It may take up to one hour to clean up for big files" >> Report.txt
        echo "In the mean time you may access the generated output, but are not advised to close your shell session" >> Report.txt
	echo "Thank you." >> Report.txt
	;;
	esac
	if [[ ! -z $email ]]; then
                mail -s "Your Job Report From HellasGrid" $email < Report.txt
        fi
	outputFolder=$(ls | sort -nr | grep -m 1 "MyOutput")
        mv Report.txt $outputFolder
}

########################################################

##### if any data are empty, exit with exit code = "1" #####
if [[ $option == 5 ]]; then
	if [[ -z "$rawDatabase" && -z "$readyDatabase" ]]; then
		echo "no database given, exit"
		Exit 1
	elif [[ -z "$geneMap" ]]; then
		echo "empty gene map, exit"
		Exit 1
	fi
else
	if [[ -z "$query" ]]; then
		echo "empty query, exit"
		Exit 1
	elif [[ -z "$geneMap" ]]; then 
		echo "empty gene map, exit"
		Exit 1
	elif [[ -z "$rawDatabase" && -z "$readyDatabase" ]]; then
		echo "no database given, exit"
  		Exit 1
	elif [[ -z "$option" ]]; then 
  		echo "no desired output is specified, exit"
  		Exit 1
	fi
fi

######## Call the Master Script  ##########

case "$option" in

1|2|3|4|5) echo "Getting Started"
   ./MasterScript.sh $input `date +"%Y%m%d%H%M%S"`
   exitstatus=$?
   Exit $exitstatus
   ;;
*) echo "Option Not supported"
   Exit 1
   ;;
esac
