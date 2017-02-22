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
        #list help
        echo "$(tput setaf 3)This is pikasub$(tput sgr0), the Pipeline Integration Kit for hpc Analysis submission script.";
        echo "";
        echo "LICENCE: GNU General Public License";
        echo "";
        echo "";
        echo "Parameters are colored $(tput setaf 3)yellow $(tput sgr0) $(tput sgr0)";

        #show config
	echo "Submitting a simple script:"
	echo "pikasub $(tput setaf 3)scriptname$(tput sgr0)";
	printf "%-20s %-20s %-20s \n" "" "scriptname" "The file, or the complete path to the file that needs to be executed";

	echo "";
	echo "Advance submission:";
	echo "pikasub $(tput setaf 3)-script scriptname$(tput sgr0)"
	printf "%-20s %-20s \n" "" "$(tput bold)MANDATORY:$(tput sgr0)";
	printf "%-20s %-20s %-20s \n" "" "-script" "The file, or the complete path to the file that needs to be executed";
        printf "%-20s %-20s \n" "" "$(tput bold)OPTIONAL:$(tput sgr0)";
        printf "%-20s %-20s %-20s \n" "" "-data" "A data file, this is a shortcut to change the used batch file in the code (handy for testing on a subset, or adding only a few samples after others are already processed)";

        oldIFS=$IFS;
        IFS='';
        while read -r line;
        do
                name=`echo $line | awk -v FS='\t' '{print $1}'`;
                message=`echo $line | awk -v FS='\t' '{print $2}'`;
		#check if name in known options
		arrayContainsElement "$name" "${ENGINE_NAME_ARRAY[@]}"
		known=$?
		if [ "$known" == 0 ];
		then
			printf "%-20s %-20s %-20s \n" "" "-$name" "$message";
		fi
        done < $BASEDIR/../engines/engines_help;
        IFS=$oldIFS;

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

start_script(){
        arrayContainsElement "-script" "${OPTION_ARRAY[@]}";
        containsBatch=$?;
        if [ "$containsBatch" == 0 ];
        then
                echo "found script is ${VALUE_ARRAY["-script"]}";
                VALUE_ARRAY["-script"]=$(copy_submitted_file ${VALUE_ARRAY["-script"]});
        else
                echo "A script to execute is missing";
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
                #add the line for setting the batch file to the script
		awk -v batchfile=${VALUE_ARRAY["-batch"]} 'BEGIN{added=0}{if(added==0 && !($1 ~ "^#")){print "BATCH_FILE=\""batchfile"\""; added=1} print $0}' ${VALUE_ARRAY["-batch"]} > ${VALUE_ARRAY["-batch"]}".tmp";
		mv ${VALUE_ARRAY["-batch"]}".tmp" ${VALUE_ARRAY["-batch"]};
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
                        #check if known variable
			arrayContainsElement "$namevar" "${ENGINE_NAME_ARRAY[@]}"
			known=$?
			if [ "$known" == 0 ];
			then
				#check if file, if copy to execution dir
				if [ -f ${VALUE_ARRAY["$name"]} ];
				then
					VALUE_ARRAY["$name"]=$(copy_submitted_file ${VALUE_ARRAY["$name"]});
				fi 
				to_add=`echo ${ENGINE_VALUE_ARRAY[$namevar]} | sed "s:$replace:${VALUE_ARRAY[$name]}:g"`;
				execution_command=$execution_command" "$to_add;

			else
				echo "Unkown option: $name"
			fi
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
