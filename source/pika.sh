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

##Parameters found in the config file
MAIL="";
BILLING="";
PROJECT_DIR="";
GENOMEDIR="";
JOBDIR="";
EXTRA_MODULES="";
MY_SCRATCH=~;
MODULE_VERSION="";
declare -A MODULE_NAME_ARRAY=();
declare -A MODULE_VERSION_ARRAY=();
##Set the paramters from the config file
set_mail;
set_billing;
set_genome_dir;
set_module_version;
set_extra_modules;
set_my_scratch;
load_modules;

#version
get_version(){
	echo "$VERSION";
}

#show help
show_help(){
	#list help
	echo "$(tput setaf 3)This is PIKA$(tput sgr0), the Pipeline Integration Kit for hpc Analysis.";
	echo "";
	echo "LICENCE: GNU General Public License";
	echo "";
        echo "These are my known jobs:";
        echo "Parameters are colored $(tput setaf 3)yellow $(tput sgr0) $(tput sgr0)";

	#show config
        echo "$(tput bold)show config $(tput sgr0)";
        printf "%-20s  %-20s \n" "" "Shows the current config parameters";
	#change config
	echo "$(tput bold)change config $(tput sgr0)";
        printf "%-20s  %-20s \n" "" "Change the current config parameters";
        #show genomes
        echo "$(tput bold)show genomes$(tput sgr0) ";
        printf "%-20s  %-20s \n" "" "Shows all installed genomes (species and build)";

#JOBS
        #list jobs
        echo "$(tput bold)job list $(tput sgr0)";
        printf "%-20s  %-20s \n" "" "Lists all known jobs/scripts";
        #show help jobs
        echo "$(tput bold)job help$(tput sgr0) $(tput setaf 3)jobname$(tput sgr0)";
        printf "%-20s  %-20s \n" "" "Shows the help of the given job";
        #show howto jobs
        echo "$(tput bold)job howto$(tput sgr0) $(tput setaf 3)jobname$(tput sgr0)";
        printf "%-20s  %-20s \n" "" "Shows the howto of the given job";
        #copy jobs
        echo "$(tput bold)job copy$(tput sgr0) $(tput setaf 3)jobname$(tput sgr0) possible_parameters=values";
        printf "%-20s  %-20s \n" "" "This task needs to be executed in the project directory. A pbs script will be created in a jobs directory (inside the project dir), the pbs will contain the default values (project_dir, mail, genome, billing, ...)";
#PIPELINES
        #list pipelines
        echo "$(tput bold)pipeline list $(tput sgr0)";
        printf "%-20s  %-20s \n" "" "Lists all known pipelines";
        #show help pipelines
        echo "$(tput bold)pipeline help$(tput sgr0) $(tput setaf 3)pipeline$(tput sgr0)";
        printf "%-20s  %-20s \n" "" "Shows the help of the given pipeline";
        #show howto jobs
        echo "$(tput bold)pipeline howto$(tput sgr0) $(tput setaf 3)pipeline$(tput sgr0)";
        printf "%-20s  %-20s \n" "" "Shows the howto of the given pipeline";
        echo "$(tput bold)pipeline copy$(tput sgr0) $(tput setaf 3)pipelineName$(tput sgr0) possible_parameters=values";
        printf "%-20s  %-20s \n" "" "This task needs to be executed in the project directory. All needed pbs scripts will be created in a jobs directory (inside the project dir), all the pbs will contain the default values (project_dir, mail, genome, billing, ...), the steps will be numbered for easy use. A pipelineName.howto file will be created with the steps to perform, including helpfull commands.";

#GLOBAL PARAMETERS
	echo "";
	echo "These are my Global parameters, you can set for every job or pipeline (does override the config file only the time when used)";
	printf "%-20s  %-20s %-20s \n" "" "MAIL" "This changes the mail adress in the scripts [Now: $MAIL]";
	printf "%-20s  %-20s %-20s \n" "" "BILLING" "This changes the used billing account for the scripts [Now: $BILLING]";
	printf "%-20s  %-20s %-20s \n" "" "SCRATCH" "This changes the to use scratch for the scripts [Now: $MY_SCRATCH]";
	printf "%-20s  %-20s %-20s \n" "" "MODULE_VERSION" "This changes the to use module version file [Now: $MODULE_VERSION]";

}


#PROGRAM
if [ "$#" -eq 0 ]
then
    show_help;
else
	i=0;
	declare -A OPTION_ARRAY;
	declare -A VALUE_ARRAY;
	for a in "$@"; 
	do
		if (($i>=3));
		then
		key=`echo "$a"| awk -v FS="=" '{print $1;}'`;
		value=`echo "$a" | awk -v FS="=" '{print $2;}'`;
		OPTION_ARRAY[$i-3]=$key;
		VALUE_ARRAY[$key]=$value;
		fi
		((i++));
	done
	#Check global variables: MAIL, BILLING, MY_SCRATCH, MODULE_VERSION 
	arrayContainsElement "MAIL" "${OPTION_ARRAY[@]}";
	containsMail=$?;
	if [ "$containsMail" == 0 ];
	then
		MAIL="${VALUE_ARRAY[MAIL]}";
	fi
	arrayContainsElement "BILLING" "${OPTION_ARRAY[@]}";
	containsBilling=$?;
	if [ "$containsBilling" == 0 ];
	then
		BILLING="${VALUE_ARRAY[BILLING]}";
	fi
	arrayContainsElement "SCRATCH" "${OPTION_ARRAY[@]}";
	containsScratch=$?;
	if [ "$containsScratch" == 0 ];
	then
		change_my_scratch ${VALUE_ARRAY[SCRATCH]};
	fi
	arrayContainsElement "MODULE_VERSION" "${OPTION_ARRAY[@]}";
	containsModuleVersion=$?;
	if [ "$containsModuleVersion" == 0 ];
	then
		check_module_exists ${VALUE_ARRAY[MODULE_VERSION]};
		exists_module=$?;
		if [ "$exists_module" == 0 ];
		then
			MODULE_VERSION="${VALUE_ARRAY[MODULE_VERSION]}";
			load_modules;
		fi
	fi

    case "$1" in
        help)
            show_help;
        ;;
	show | list)
		case "$2" in
			config)
				check_config_file;
			;;
			jobs)
				show_jobs;
			;;
			genomes)
				show_genomes;
			;;
			pipelines)
				show_pipelines;
			;;
			modules)
				show_modules;
			;;
			*)
				echo "Usage: $0 $1 {config|jobs|genomes|pipelines|modules}";
				exit 1;
			;;
		esac
	;;
	change)
		case "$2" in
			config)
				change_config;	
			;;
			*)
				echo "Usage: $0 change {config}";
				exit 1;
			;;
		esac
	;;
	job)
		case "$2" in
			list)
				show_jobs;
			;;
			help)
				show_job_help $3;
			;;
			howto)
				show_job_howto $3;
			;;
			copy)
				set_jobs_dir;
                                copy_job $3;
			;;
			*)
				echo "Usage: $0 job {list|help|howto|copy}";
				exit 1;
			;;
		esac
	;;
	pipeline)
		case "$2" in
                        list)
                                show_pipelines;
                        ;;
			help)
                                show_pipeline_help $3;
			;;
			howto)
                                show_pipeline_howto $3;
			;;
			copy)
				set_jobs_dir;
				copy_pipeline $3;
			;;
			*)
				echo "Usage: $0 pipeline {list|help|howto|copy}";
				exit 1;
			;;
		esac
	;;
	*)
		echo "Usage: $0 {help|show|list|change|job|pipeline}";
		exit 1;	
	;;
    esac
fi



