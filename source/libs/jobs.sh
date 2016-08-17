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
	check_job $1;
	correct_job=$?;
	if [ "$correct_job" == 0 ]
	then
		echo "The help of $1";
		#correct job
		grep "##\[HELP\]" $BASEDIR/../scripts/*/$1.pbs | sed 's/##\[HELP\] /\t/g';		
	fi
}

show_job_howto(){
	check_job $1;
        correct_job=$?;
        if [ "$correct_job" == 0 ]
        then
                echo "The howto of $1";
                #correct job
                grep "##\[HOWTO\]" $BASEDIR/../scripts/*/$1.pbs | sed 's/##\[HOWTO\] /\t/g';
        fi
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
                        echo "No job found with this name";
			correct=1;
                fi
		if [ `ls -1 -d $BASEDIR/../scripts/*/$1.pbs 2>/dev/null | wc -l` -gt 1 ];
		then
			#multiple job for the name
			echo "Multiple jobs found with this name";
			correct=1;
		fi
        fi
	return "$correct";
}


copy_job(){
	#parameters must be job, and species/build
	if [ $# -lt 2 ];
	then
		echo "All copies must have a jobname and a species/build";
	else
		check_job $1;
		correct_job=$?;
		check_genome $2;
		correct_species=$?;
		prefix="";
		if [ $# -ge 3 ];
		then
			#has prefix
			prefix=$3;
		fi
		if [ "$correct_job" == 0 ] && [ "$correct_species" == 0 ];
        	then
			#copy the job, and change the standard values
			cp $BASEDIR/../scripts/*/$1.* $PROJECT_DIR/jobs;
			rm $PROJECT_DIR/jobs/$1.pbs;
			cat $BASEDIR/../scripts/*/$1.pbs | sed "s:MAIL:$MAIL:g" | sed "s:default_project:$BILLING:g" | sed "s:PROJECT_DIR=\"\":PROJECT_DIR=\"$PROJECT_DIR\":" | sed "s:GENOME_DIR=\"\":GENOME_DIR=\"$GENOMEDIR/$2\":" > $PROJECT_DIR/jobs/$prefix$1.pbs;
			#change possible prologs
			if [ -f $PROJECT_DIR/jobs/$1.prolog.sh ];
			then
				rm $PROJECT_DIR/jobs/$1.prolog.sh;
				cat $BASEDIR/../scripts/*/$1.prolog.sh | sed "s:MAIL:$MAIL:g" | sed "s:default_project:$BILLING:g" | sed "s:PROJECT_DIR=\"\":PROJECT_DIR=\"$PROJECT_DIR\":" | sed "s:GENOME_DIR=\"\":GENOME_DIR=\"$GENOMEDIR/$2\":" > $PROJECT_DIR/jobs/$prefix$1.prolog.sh;
			fi
			echo "Copied the job $1";
		fi
	fi
}
