#!/bin/bash -x

# first argument is the type of jdl file I want
# second argument is the number of jobs that will run or the number of abc files that will be collected for the simple jobs
# third argument is the name of the jdl file
# fourth argument is the running option, passed as an argument to the script the jobs will run

jobType=${1}
num=${2}
file=${3}
option=${4}

if [[ $jobType == "Parametric" ]]; then
	echo "Type = \"Job\"; " >> $file
	echo "JobType = \"Parametric\";" >> $file
	echo "Executable = \"JobScript.sh\";" >> $file
	echo "Arguments = \"_PARAM_ fastafiles tools $option\";" >> $file
	echo "InputSandbox = {\"JobScript.sh\"};" >> $file
	echo "ParameterStart = 1;" >> $file
	echo "ParameterStep = 1;" >> $file
	echo "Parameters = $num;" >> $file
	echo "StdOutput = \"std_PARAM_.out\";" >> $file
	echo "StdError = \"std_PARAM_.err\";" >> $file
	echo "OutputSandbox = {\"std_PARAM_.out\",\"std_PARAM_.err\"};" >> $file
	echo "Requirements = (other.GlueCEInfoHostName == \"cox01.grid.metu.edu.tr\") || (other.GlueCEInfoHostName == \"kalkan1.ulakbim.gov.tr\") || (other.GlueCEInfoHostName == \"snf-189278.vm.okeanos.grnet.gr\");" >> $file

elif [[ $jobType == "SimpleMcl" || $jobType == "PhylMcl" ]]; then
	echo "Type = \"Job\";" >> $file
	echo "JobType = \"Normal\";" >> $file
	echo "Executable = \"RunMclForTheUploadedABCFiles.sh\";" >> $file
	if [[ $jobType == "SimpleMcl" ]]; then
		echo "Arguments = \"$num output\";" >> $file
	else
		echo "Arguments = \"$num phyl\";" >> $file
	fi
	echo "InputSandbox = {\"RunMclForTheUploadedABCFiles.sh\"};" >> $file
	echo "StdOutput = \"std.out\";" >> $file
	echo "StdError = \"std.err\";" >> $file
	echo "OutputSandbox = {\"std.out\",\"std.err\",\"outmcl.tar.gz\"};" >> $file
	echo "Requirements = (other.GlueCEInfoHostName == \"cox01.grid.metu.edu.tr\") || (other.GlueCEInfoHostName == \"kalkan1.ulakbim.gov.tr\") || (other.GlueCEInfoHostName == \"snf-189278.vm.okeanos.grnet.gr\");" >> $file
fi
