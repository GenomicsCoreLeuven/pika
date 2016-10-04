#!/bin/sh

show_jobs(){
	jobdir="$BASEDIR/../scripts/";
	for category in `ls -1 -d $jobdir* | sed "s:$jobdir::g"`;
	do
		echo $category;	
		for task in `ls -1 -d $BASEDIR/../scripts/$category/*.pbs | sed "s:$BASEDIR/../scripts/$category/::g" | sed 's/.pbs//g'`;
		do
			printf "%-20s  %-20s \n" "" "$task";	
		done
	done	
}


show_job_help(){
	check_job_exists $1;
	correct_job=$?;
	if [ "$correct_job" == 0 ]
	then
		echo "The help of $1";
		#correct job
		grep "##\[HELP\]" $BASEDIR/../scripts/*/$1.pbs | sed 's/##\[HELP\] /\t/g';		
	fi
}

show_job_howto(){
	check_job_exists $1;
        correct_job=$?;
        if [ "$correct_job" == 0 ]
        then
                echo "The howto of $1";
                #correct job
                grep "##\[HOWTO\]" $BASEDIR/../scripts/*/$1.pbs | sed 's/##\[HOWTO\] /\t/g';
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
                if [ `ls -1 -d $BASEDIR/../scripts/*/$1.pbs 2>/dev/null | wc -l` -eq 0 ];
                then
                        #jobname does not exists
                        echo "No job found with this name: $1";
                        correct=1;
                fi
                if [ `ls -1 -d $BASEDIR/../scripts/*/$1.pbs 2>/dev/null | wc -l` -gt 1 ];
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
                if [ `ls -1 -d $BASEDIR/../scripts/*/$1.pbs 2>/dev/null | wc -l` -eq 0 ];
                then
                        #jobname does not exists
                        echo "No job found with this name: $1";
			correct=1;
                fi
		if [ `ls -1 -d $BASEDIR/../scripts/*/$1.pbs 2>/dev/null | wc -l` -gt 1 ];
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
			for option in `grep "##\[OPTIONS\]" $BASEDIR/../scripts/*/$1.pbs | grep "mandatory" | awk '{print $2;}'`;
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
			#copy the job, and change the standard values
			cp $BASEDIR/../scripts/*/$1.* $JOBDIR;
			rm $JOBDIR/$1.pbs;
			cat $BASEDIR/../scripts/*/$1.pbs | sed "s:MAIL:$MAIL:g" | sed "s:default_project:$BILLING:g" | sed "s:PROJECT_DIR=\"\":PROJECT_DIR=\"$PROJECT_DIR\":" | sed "s:GENOME_DIR=\"\":GENOME_DIR=\"$GENOMEDIR/\":" | sed "s:SCRATCH_DIR=~;:SCRATCH_DIR=$MY_SCRATCH;:g" > $JOBDIR/$prefix$1.pbs;
			
			#add possible extra sources
			cat $JOBDIR/$prefix$1.pbs | sed "s:#extra_modules:$EXTRA_MODULES:g" > $JOBDIR/$prefix$1.pbs.tmp;
			mv $JOBDIR/$prefix$1.pbs.tmp $JOBDIR/$prefix$1.pbs;
			
			#change modules if versions are specified
			if [ "${#MODULE_NAME_ARRAY[@]}" != "0" ];
			then
				#known modules
				for module_name in "${MODULE_NAME_ARRAY[@]}";
				do
					module_version="${MODULE_VERSION_ARRAY[$module_name]}";
					cat $JOBDIR/$prefix$1.pbs | sed "s:^module load $module_name$:module load $module_version:g" > $JOBDIR/$prefix$1.pbs.tmp;
					mv $JOBDIR/$prefix$1.pbs.tmp $JOBDIR/$prefix$1.pbs;
				done
			fi
			
			#change the options
			for option in "${OPTION_ARRAY[@]}";
			do
				if [ "$option" != "genome" ];
				then
				value="${VALUE_ARRAY["$option"]}";
				action=`grep "##\[OPTIONS\]" $BASEDIR/../scripts/*/$1.pbs | grep $option | awk -v FS='\t' '{print $3}' | sed "s:value:$value:"`;
				if [ ! -z "$action" ];
				then
					echo "cat $JOBDIR/$prefix$1.pbs | $action > $JOBDIR/$prefix$1.pbs.tmp" | sh;
					mv $JOBDIR/$prefix$1.pbs.tmp $JOBDIR/$prefix$1.pbs;
					fi
				fi
			done


			#change possible prologs
			if [ -f $JOBDIR/$1.prolog.sh ];
			then
				rm $JOBDIR/$1.prolog.sh;
				cat $BASEDIR/../scripts/*/$1.prolog.sh | sed "s:MAIL:$MAIL:g" | sed "s:default_project:$BILLING:g" | sed "s:PROJECT_DIR=\"\":PROJECT_DIR=\"$PROJECT_DIR\":" | sed "s:GENOME_DIR=\"\":GENOME_DIR=\"$GENOMEDIR/\":" > $JOBDIR/$prefix$1.prolog.sh;
				#change modules if versions are specified in prolog
				if [ "${#MODULE_NAME_ARRAY[@]}" != "0" ];
				then
					#known modules
					for module_name in "${MODULE_NAME_ARRAY[@]}";
					do
						module_version="${MODULE_VERSION_ARRAY[$module_name]}";
						cat $JOBDIR/$prefix$1.prolog.sh | sed "s:^module load $module_name$:module load $module_version:g" > $JOBDIR/$prefix$1.prolog.sh.tmp;
						mv $JOBDIR/$prefix$1.prolog.sh.tmp $JOBDIR/$prefix$1.prolog.sh;
					done
				fi
			fi
			echo "Copied the job $1";
		fi
	fi




}
