#!/bin/bash

# first argument is the type of jdl file I want
# second argument is the number of jobs that will run or the number of abc files that will be collected for the simple jobs
# third argument is the name of the jdl file
# fourth argument is the running option, passed as an argument to the script the jobs will run
# fifth argument is the timestamp of the folder where the data created by the app resides
# sixth argument is a parameter needed for mcl, in order to pre-process or not the data it is given (value may be omitted)

jobType=${1}
jobNum=${2}
file=${3}
option=${4}
timestamp=${5}
I_or_E=${6}

# user name for job data to upload
userName=`whoami`

if [[ $jobType == "Parametric" ]]; then
	echo "Type = \"Job\"; " >> $file
	echo "JobType = \"Parametric\";" >> $file
	echo "Executable = \"JobScript.sh\";" >> $file
	echo "Arguments = \"_PARAM_ fastafiles tools $option $userName $timestamp\";" >> $file
	echo "InputSandbox = {\"JobScript.sh\"};" >> $file
	echo "ParameterStart = 1;" >> $file
	echo "ParameterStep = 1;" >> $file
	echo "Parameters = $jobNum;" >> $file
	echo "StdOutput = \"std_PARAM_.out\";" >> $file
	echo "StdError = \"std_PARAM_.err\";" >> $file
	echo "OutputSandbox = {\"std_PARAM_.out\",\"std_PARAM_.err\"};" >> $file
	echo "Requirements = (other.GlueCEInfoHostName == \"cox01.grid.metu.edu.tr\") || (other.GlueCEInfoHostName == \"kalkan1.ulakbim.gov.tr\") || (other.GlueCEInfoHostName == \"snf-189278.vm.okeanos.grnet.gr\") || (other.GlueCEInfoHostName == \"cream-ce01.marie.hellasgrid.gr\") || (other.GlueCEInfoHostName == \"cream-ce01.ariagni.hellasgrid.gr\");" >> $file

elif [[ $jobType == "SimpleMcl" || $jobType == "PhylMcl" ]]; then
	echo "Type = \"Job\";" >> $file
	echo "JobType = \"Normal\";" >> $file
	echo "Executable = \"SecondJobScript.sh\";" >> $file
	if [[ $jobType == "SimpleMcl" ]]; then
		echo "Arguments = \"$jobNum output $userName $option $timestamp $I_or_E\";" >> $file
	else
		echo "Arguments = \"$jobNum phyl $userName $option $timestamp\";" >> $file
	fi
	echo "InputSandbox = {\"SecondJobScript.sh\",\"tools/Upload.sh\"};" >> $file
	echo "StdOutput = \"std.out\";" >> $file
	echo "StdError = \"std.err\";" >> $file
	echo "OutputSandbox = {\"std.out\",\"std.err\"};" >> $file
	echo "Requirements = (other.GlueCEInfoHostName == \"cox01.grid.metu.edu.tr\") || (other.GlueCEInfoHostName == \"kalkan1.ulakbim.gov.tr\") || (other.GlueCEInfoHostName == \"snf-189278.vm.okeanos.grnet.gr\");" >> $file
fi
