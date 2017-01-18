#!/bin/sh

show_jobs(){
	jobdir="$BASEDIR/../scripts/$MODULE_VERSION/";
	liststring=`ls -d $jobdir* | sed "s:$jobdir:,:g" | tr -dc '[:print:]' | sed 's:^,::g'`;
	oldIFS=$IFS
	IFS=', ' read -r -a array <<< "$liststring";
	for category in ${array[@]};
	do
		echo $category;	
		taskstring=`ls -1 -d $BASEDIR/../scripts/$MODULE_VERSION/$category/*.script | sed "s:$BASEDIR/../scripts/$MODULE_VERSION/$category/:,:g" | sed 's/.script//g' | tr -dc '[:print:]' | sed 's:^,::g'`;
		IFS=', ' read -r -a taskarray <<< "$taskstring";
		for task in ${taskarray[@]};
		do
			printf "%-20s  %-20s \n" "" "$task";
		done
	done
	IFS=$oldIFS;
}


show_job_help(){
	check_job_exists $1;
	correct_job=$?;
	if [ "$correct_job" == 0 ]
	then
		echo "The help of $1";
		#correct job
		grep "##\[HELP\]" $BASEDIR/../scripts/$MODULE_VERSION/*/$1.script | sed 's/##\[HELP\] /\t/g';
	fi
}

show_job_howto(){
	check_job_exists $1;
        correct_job=$?;
        if [ "$correct_job" == 0 ]
        then
                echo "The howto of $1";
                #correct job
                grep "##\[HOWTO\]" $BASEDIR/../scripts/$MODULE_VERSION/*/$1.script | sed 's/##\[HOWTO\] /\t/g';
        fi
}

check_job_exists(){
	correct=0;
	if [ $# -eq 0 ];
	then
		echo "No parameter given";
		correct=1;
	else
		#a jobname is given
                if [ `ls -1 -d $BASEDIR/../scripts/$MODULE_VERSION/*/$1.script 2>/dev/null | wc -l` -eq 0 ];
                then
                        #jobname does not exists
                        echo "No job found with this name: $1";
                        correct=1;
                fi
                if [ `ls -1 -d $BASEDIR/../scripts/$MODULE_VERSION/*/$1.script 2>/dev/null | wc -l` -gt 1 ];
                then
                        #multiple job for the name
                        echo "Multiple jobs found with this name: $1";
                        correct=1;
                fi

        fi
        return "$correct";
}

check_job(){
	correct=0;
	if [ $# -eq 0 ];
        then
                echo "No parameter given";
		correct=1;
        else
                #a jobname is given
                if [ `ls -1 -d $BASEDIR/../scripts/$MODULE_VERSION/*/$1.script 2>/dev/null | wc -l` -eq 0 ];
                then
                        #jobname does not exists
                        echo "No job found with this name: $1";
			correct=1;
                fi
		if [ `ls -1 -d $BASEDIR/../scripts/$MODULE_VERSION/*/$1.script 2>/dev/null | wc -l` -gt 1 ];
		then
			#multiple job for the name
			echo "Multiple jobs found with this name: $1";
			correct=1;
		fi
		if [ "$correct" -eq 0 ];
		then
			#check the options
			declare -A optionList;
			optionCount=0;
			for option in `grep "##\[OPTIONS\]" $BASEDIR/../scripts/$MODULE_VERSION/*/$1.script | grep "mandatory" | awk '{print $2;}'`;
			do
				optionList[$optionCount]="$option";
				optionCount=$((optionCount+1));
			done 
			for neededOption in "${optionList[@]}";
			do
				arrayContainsElement "$neededOption" "${OPTION_ARRAY[@]}";
				contains=$?;
				if [ "$contains" == 1 ];
				then
				echo "The mandatory options $neededOption for job $1 is missing";
				correct=1;
				fi
			done
		fi
        fi
	return "$correct";
}


copy_job(){
	#parameters must be job, and species/build
	if [ $# -lt 1 ];
	then
		echo "All copies must have a jobname";
	else
		check_job $1;
		correct_job=$?;
		#check if genome exists and is needed
		arrayContainsElement "genome" "${OPTION_ARRAY[@]}";
		containsGenome=$?;
		if [ "$containsGenome" == 0 ];
		then
			check_genome ${VALUE_ARRAY["genome"]};
			correct_species=$?;
		else
			correct_species=0;
		fi
		prefix="";
		arrayContainsElement "prefix" "${OPTION_ARRAY[@]}";
		containsPrefix=$?;
		if [ "$containsPrefix" == 0 ];
		then
			#has prefix
			prefix=${VALUE_ARRAY["prefix"]};
		fi
		if [ "$correct_job" == 0 ] && [ "$correct_species" == 0 ];
		then
			#copy the job
			cp $BASEDIR/../scripts/$MODULE_VERSION/*/$1* $JOBDIR;
			if [ -f $JOBDIR/$1.script ];
			then
				mv $JOBDIR/$1.script $JOBDIR/$prefix$1.$extention;
				script_to_engine $JOBDIR/$prefix$1.$extention;
				copy_and_correct_script $JOBDIR/$prefix$1.$extention;
			fi
			if [ -f $JOBDIR/$1.prolog.sh ];
			then
				mv $JOBDIR/$1.prolog.sh $JOBDIR/$prefix$1.prolog.sh;
				copy_and_correct_script $JOBDIR/$prefix$1.prolog.sh;
			fi
			if [ -f $JOBDIR/$1.epilog.sh ];
			then
				mv $JOBDIR/$1.epilog.sh $JOBDIR/$prefix$1.epilog.sh;
				copy_and_correct_script $JOBDIR/$prefix$1.epilog.sh;
			fi
			echo "Copied the job $1";
		fi
	fi
}



copy_and_correct_script(){
	if [ "$1" == "" ] || [ ! -f $1 ];
	then
		return 1;
	else
		script=$1;
		cat $script | sed "s:MAIL:$MAIL:g" | sed "s:default_project:$BILLING:g" | sed "s:PROJECT_DIR=\"\":PROJECT_DIR=\"$PROJECT_DIR\":" | sed "s:GENOME_DIR=\"\":GENOME_DIR=\"$GENOMEDIR/\":" | sed "s:SCRATCH_DIR=~;:SCRATCH_DIR=$MY_SCRATCH;:g" > $script.tmp;

		mv $script.tmp $script;
		#add possible extra sources
		cat $script | sed "s:#extra_modules:$EXTRA_MODULES:g" > $script.tmp;
		mv $script.tmp $script;

		#change modules if versions are specified
		if [ "${#MODULE_NAME_ARRAY[@]}" != "0" ];
		then
			#known modules
			for module_name in "${MODULE_NAME_ARRAY[@]}";
			do
			module_version="${MODULE_VERSION_ARRAY[$module_name]}";
			cat $script | sed "s:^module load $module_name$\|^module load $module_name;$:module load $module_version;:g" > $script.tmp;
			mv $script.tmp $script;
			cat $script | sed "s:^version_$module_name=\"$module_name\":version_$module_name=\"$module_version\":g" > $script.tmp;
                        mv $script.tmp $script;
			done
		fi

		#change the options
		for option in "${OPTION_ARRAY[@]}";
		do
			if [ "$option" != "genome" ];
			then
				value="${VALUE_ARRAY["$option"]}";
				action=`grep "##\[OPTIONS\]" $script | grep $option | awk -v FS='\t' '{print $3}' | sed "s:value:$value:"`;
				if [ ! -z "$action" ];
				then
					echo "cat $script | $action > $script.tmp" | sh;
					mv $script.tmp $script;
				fi
			fi
		done
	fi
	return 0; 
}






