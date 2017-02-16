#!/bin/sh
VERSION="pika 16.08 dev";
BASEDIR=$(dirname $0);
LIB_DIR="$BASEDIR/libs";
source $LIB_DIR/variables_and_settings.sh;
source $LIB_DIR/jobs.sh;
source $LIB_DIR/genomes.sh;
source $LIB_DIR/pipelines.sh;
source $LIB_DIR/extra_code.sh;
source $LIB_DIR/modules.sh;
source $LIB_DIR/engines.sh;

##Parameters found in the config file
MAIL="";
BILLING="";
PROJECT_DIR="";
GENOMEDIR="";
JOBDIR="";
EXTRA_MODULES="";
MY_SCRATCH=~;
MODULE_VERSION="";
GRID_ENGINE="";
declare -A MODULE_NAME_ARRAY=();
declare -A MODULE_VERSION_ARRAY=();
##Set the paramters from the config file
set_mail;
set_billing;
set_genome_dir;
set_module_version;
set_extra_modules;
set_my_scratch;
set_grid_engine;
load_modules;
set_grid_parameters;
#version
get_version(){
	echo "$VERSION";
}

show_help(){
	echo "TODO Help";
}

copy_submitted_file(){
	local file=`pwd`;
	mkdir -p $file/submitted;
	filename=`echo $1 | awk -v FS="/" '{print $NF}'`;
	cp $1 $file/submitted/$now"_"$filename;
	file=$file"/submitted/"$now"_"$filename;
	echo "$file";
}

start_single_job(){
	local file=$1;
	file=$(copy_submitted_file $file);
	execution_command=${ENGINE_VALUE_ARRAY["submission"]}" "$file;
}

start_batch_job(){
	arrayContainsElement "-batch" "${OPTION_ARRAY[@]}";
	containsBatch=$?;
	if [ "$containsBatch" == 0 ];
	then
 		echo "batch is ${VALUE_ARRAY["-batch"]}";
		VALUE_ARRAY["-batch"]=$(copy_submitted_file ${VALUE_ARRAY["-batch"]});
	else
		echo "A batch file is missing";
		exit 1;
	fi
	execution_command=${ENGINE_VALUE_ARRAY["submission"]};
	arrayContainsElement "-data" "${OPTION_ARRAY[@]}";
	containsData=$?;
	if [ "$containsData" == 0 ];
	then
		#contains data file
		VALUE_ARRAY["-data"]=$(copy_submitted_file ${VALUE_ARRAY["-data"]});
		if [ ! -f ${VALUE_ARRAY["-data"]} ];
		then
			echo "No file with the path: ${VALUE_ARRAY["-data"]} found";
			exit 1;
		fi
		if [ `grep "#batchline" ${VALUE_ARRAY["-batch"]} | wc -l` == "0" ];
		then
			echo "This is not a batch script";
			exit 1;
		fi
		#check if job array can be executed
		arrayContainsElement "job_array" "${ENGINE_NAME_ARRAY[@]}";
		containsJobArray=$?
		arrayContainsElement "job_array_index" "${ENGINE_NAME_ARRAY[@]}";
		containsJobArrayIndex=$?;
		if [ "$containsJobArray" != 0 ] || [ "$containsJobArrayIndex" != 0 ];
		then
			#not able to execute
			echo "The grid engine can not execute batch jobs (probably an error in the engine setup file)";
			exit 1;
		fi
		#file exists (else exit)
		#calculate number of jobs
		jobNr=`cat ${VALUE_ARRAY["-data"]} | wc -l | awk '{print $1-1;}'`;
		echo "Found $jobNr tasks";
		#add the batch line to the file
		batchline="declare \$(awk -v linenr="${ENGINE_VALUE_ARRAY["job_array_index"]}" -v FS=',' '{if(NR==1){for(i=1; i<=NF; i++){arr[i]=\$i;}}if(NR==(linenr+1)){for(i=1; i<=NF; i++){print arr[i]\"=\"\$i;}}}' ${VALUE_ARRAY["-data"]});";
		sed "s:#batchline:$batchline:g" ${VALUE_ARRAY["-batch"]} > ${VALUE_ARRAY["-batch"]}".tmp";
		mv ${VALUE_ARRAY["-batch"]}".tmp" ${VALUE_ARRAY["-batch"]};
		execution_command=$execution_command" "${ENGINE_VALUE_ARRAY["job_array"]};
		execution_command=`echo $execution_command | sed "s/ARRAY_INTERVAL/$jobNr/g"`;
	fi
	#check other parameters
	local ignore_array=("batch" "data");
	for name in "${OPTION_ARRAY[@]}";
	do
		namevar=`echo $name | sed 's:-::g'`;
		arrayContainsElement "$namevar" "${ignore_array[@]}";
		containsIgnoreElement=$?;
		if [ "$containsIgnoreElement" != 0 ];
		then
			#add variable to the execution command
			echo "check $name";
			replace=`echo $namevar | awk '{print toupper($0)}'`;
			#if is a file, copy to the execution dir
			to_add=`echo ${ENGINE_VALUE_ARRAY[$namevar]} | sed "s:$replace:${VALUE_ARRAY[$name]}:g"`;
			execution_command=$execution_command" "$to_add;
		fi
	done
	execution_command=$execution_command" "${VALUE_ARRAY["-batch"]};	
}

#PROGRAM MAIN
if [ "$#" -eq 0 ]
then
	show_help;
else
	now=$(date +%Y_%m_%d_%H_%M);
	if [ "$#" -eq 1 ]
	then
		start_single_job $1;
	else
		i=0;
		declare -A OPTION_ARRAY;
		declare -A VALUE_ARRAY;
		for a in "$@";
		do
			if [ $((i%2)) -eq 0 ];
			then
				key=$a;
			else
				value=$a;
				OPTION_ARRAY[$((i/2))]=$key;
				VALUE_ARRAY[$key]=$value;
			fi
			((i++));
		done
		#check the parameters
		declare ignore_array=("batch" "data");
		for name in "${OPTION_ARRAY[@]}";
		do
			namevar=`echo $name | sed 's:-::g'`;
			arrayContainsElement "$namevar" "${ENGINE_NAME_ARRAY[@]}";
			containsName=$?;
			arrayContainsElement "$namevar" "${ignore_array[@]}";
			containsIgnoreElement=$?;
			if [ "$containsName" != 0 ] && [ "$containsIgnoreElement" != 0 ];
			then
				#could not found element
				echo "The option $name was not found.";
				exit 1;
			fi
		done
		#parameters are checked, check if this is a batch execution
		arrayContainsElement "-batch" "${OPTION_ARRAY[@]}";
		containsBatch=$?;
		if [ "$containsBatch" == 0 ];
		then
 			start_batch_job;
		else
			echo "A batch file is missing";
			exit 1;
		fi
	fi

        (cd submitted;
	echo $execution_command;
	echo $execution_command | sh;)
fi
