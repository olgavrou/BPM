#!/bin/bash

#-- MakeJDLFile.sh ----------------------------------------------------------------------
#
# This script creates the needed jdl files
#
# Arguments: 
# 1. Type of jdl file to be created
# 2. The number of jobs that will run or the number of abc files that will be collected 
#	for the simple jobs
# 3. The name of the jdl file to be created
# 4. The delected option, passed as an argument to the script the jobs will run
# 5. The timestamp of the folder where the data created resides
# 6. A parameter needed for mcl, in order to pre-process or 
#	not the data it is given [optional]
#
#----------------------------------------------------------------------------------------


jobType=${1}
startNum=${2}
stopNum=${3}
file=${4}
option=${5}
timestamp=${6}
I_or_E=${7}

# user name for job data to upload
userName=`whoami`

if [[ $jobType == "Parametric" ]]; then
	echo "Type = \"Job\"; " >> $file
	echo "JobType = \"Parametric\";" >> $file
	echo "Executable = \"JobScript.sh\";" >> $file
	echo "Arguments = \"_PARAM_ fastafiles tools $option $userName $timestamp\";" >> $file
	echo "InputSandbox = {\"JobScript.sh\"};" >> $file
	echo "ParameterStart = $startNum;" >> $file
	echo "ParameterStep = 1;" >> $file
	echo "Parameters = $stopNum;" >> $file
	echo "StdOutput = \"std_PARAM_.out\";" >> $file
	echo "StdError = \"std_PARAM_.err\";" >> $file
	echo "OutputSandbox = {\"std_PARAM_.out\",\"std_PARAM_.err\"};" >> $file
	echo "VirtualOrganisation = \"see\";" >> $file
#	echo "Requirements = (other.GlueCEInfoHostName == \"cox01.grid.metu.edu.tr\") || (other.GlueCEInfoHostName == \"snf-189278.vm.okeanos.grnet.gr\") || (other.GlueCEInfoHostName == \"cream-ce01.marie.hellasgrid.gr\") || (other.GlueCEInfoHostName == \"cream-ce01.ariagni.hellasgrid.gr\") || (other.GlueCEInfoHostName == \"kalkan1.ulakbim.gov.tr\");" >> $file

elif [[ $jobType == "SimpleMcl" || $jobType == "PhylMcl" ]]; then
	echo "Type = \"Job\";" >> $file
	echo "JobType = \"Normal\";" >> $file
	echo "Executable = \"SecondJobScript.sh\";" >> $file
	if [[ $jobType == "SimpleMcl" ]]; then
		echo "Arguments = \"$startNum output $userName $option $timestamp $I_or_E\";" >> $file
	else
		echo "Arguments = \"$startNum phyl $userName $option $timestamp\";" >> $file
	fi
	echo "InputSandbox = {\"SecondJobScript.sh\",\"tools/Upload.sh\"};" >> $file
	echo "StdOutput = \"std.out\";" >> $file
	echo "StdError = \"std.err\";" >> $file
	echo "OutputSandbox = {\"std.out\",\"std.err\"};" >> $file
	echo "VirtualOrganisation = \"see\";" >> $file
	#echo "Requirements = (other.GlueCEInfoHostName == \"cox01.grid.metu.edu.tr\") || (other.GlueCEInfoHostName == \"kalkan1.ulakbim.gov.tr\") || (other.GlueCEInfoHostName == \"snf-189278.vm.okeanos.grnet.gr\");" >> $file
fi
