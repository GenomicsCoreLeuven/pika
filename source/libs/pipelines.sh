#!/bin/sh

show_pipelines(){
	jobdir="$BASEDIR/../pipelines/";
	for pipeline in `ls -1 -d $jobdir* | sed "s:$jobdir::g"`;
	do
		echo $pipeline;	
	done	
}


show_pipeline_help(){
	check_pipeline_exists $1;
	correct_pipeline=$?;
	if [ "$correct_pipeline" == 0 ]
	then
		echo "The help of $1";
		grep "##\[HELP\]" $BASEDIR/../pipelines/$1 | sed 's/##\[HELP\] /\t/g';		
	fi
}

show_pipeline_howto(){
	check_pipeline_exists $1;
        correct_pipeline=$?;
        if [ "$correct_pipeline" == 0 ]
        then
                echo "The howto of $1";
                grep "##\[HOWTO\]" $BASEDIR/../pipelines/$1 | sed 's/##\[HOWTO\] /\t/g';
        fi
}


check_pipeline_exists(){
	correct_pipeline=0;
        if [ $# -eq 0 ];
        then
                echo "No parameter given";
                correct_pipeline=1;
        else
                #a pipeline is given
                if [ `ls -1 -d $BASEDIR/../pipelines/$1 2>/dev/null | wc -l` -eq 0 ];
                then
                        #pipeline does not exists
                        echo "No pipeline found with this name";
                        correct_pipeline=1;
                fi
                if [ `ls -1 -d $BASEDIR/../pipelines/$1 2>/dev/null | wc -l` -gt 1 ];
                then
                        #multiple pipelines for the name
                        echo "Multiple pipelines found with this name";
                        correct_pipeline=1;
                fi
        fi
        return "$correct_pipeline";
}

check_pipeline(){
	correct_pipeline=0;
	if [ $# -eq 0 ];
        then
                echo "No parameter given";
		correct_pipeline=1;
        else
                #a pipeline is given
                if [ `ls -1 -d $BASEDIR/../pipelines/$1 2>/dev/null | wc -l` -eq 0 ];
                then
                        #pipeline does not exists
                        echo "No pipeline found with this name";
			correct_pipeline=1;
                fi
		if [ `ls -1 -d $BASEDIR/../pipelines/$1 2>/dev/null | wc -l` -gt 1 ];
		then
			#multiple pipelines for the name
			echo "Multiple pipelines found with this name";
			correct_pipeline=1;
		fi
		if [ "$correct_pipeline" -eq 0 ];
		then
			#correct pipeline
			echo "checking jobs mandatory parameters";
			joblist=(`grep "##\[JOB\]" $BASEDIR/../pipelines/$1 | awk '{if(NR==1){list=$2}else{list=list" "$2}}END{print list;}'`);
			for job in "${joblist[@]}";
			do
				check_job $job;
				outcome=$?;
				if [ "$outcome" -eq "1" ];
				then
					correct_pipeline=1;
				fi
			done
		fi
        fi
	return "$correct_pipeline";
}


copy_pipeline(){
	#parameters must be pipeline, and species/build
	if [ $# -lt 1 ];
	then
		echo "All copies must have a pipeline";
	else
		echo "Checking pipeline";
		check_pipeline $1;
		correct_pipeline=$?;
		echo "Checking genome";
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
		correct_species=$?;
		if [ "$correct_pipeline" == 0 ] && [ "$correct_species" == 0 ]
        	then
			#copy the pipeline, and change the standard values
			echo "Copy the pipeline";
			#create a new pipeline directory into the jobs directory
			mkdir -p $JOBDIR/$1;
			JOBDIR="$JOBDIR/$1";
			cd $JOBDIR;
			#cat $BASEDIR/../pipelines/$1 | grep -v "##\[HELP\]" | grep -v "##\[CHANGE\]" | sed "s:##\[HOWTO\] ::g" > $1.howto;
			IFS=$'\n';
			job="";
			jobNR=0;
			for line in `cat $BASEDIR/../pipelines/$1`;
			do
				#check if line is ##[JOB]
				case $line in
					"##[JOB]"*)
						jobNR=$((jobNR+1));
						job=`echo $line | sed 's:##\[JOB\] ::g'`;
						prefix="step"$jobNR"_";
						arrayContainsElement "prefix" "${OPTION_ARRAY[@]}";
						containsPrefix=$?;
						if [ "$containsPrefix" != 0 ];
						then
							OPTION_ARRAY+="prefix";
						fi
						VALUE_ARRAY["prefix"]="$prefix";
						copy_job $job;
						#insert the howto of the job into the howto of the pipeline
						echo "" >> $1.howto;
						grep "##\[HOWTO\]" $BASEDIR/../scripts/*/$job.pbs | sed "s:##\[HOWTO\] ::g" | sed "s:$job:$prefix$job:g" >> $1.howto;
						echo "" >> $1.howto;
					;;
					"##[CHANGE]"*)
						change=`echo $line | awk -v FS='\t' '{print $2;}'`;
						mv $prefix$job.pbs $prefix$job.tmp;
                                        	echo "cat $prefix$job.tmp | $change > $prefix$job.pbs" | sh;
                                        	rm $prefix$job.tmp;
					;;
					"##[HELP]"*)
						#help must not be printed
					;;
					"##[HOWTO]"*)
						#howto must be just "comments"
						echo $line | sed "s:##\[HOWTO\] :#:g" >> $1.howto
					;;
					*)
						echo $line >> $1.howto;
					;;
				esac
			done
			unset IFS;



			echo "Copied all jobs of the pipeline $1. Added the file $1.howto with the description on how to run this pipeline.";
		fi
	fi
}


copy_pipeline_backup(){
        #parameters must be pipeline, and species/build
        if [ $# -ne 2 ];
        then
                echo "All copies must have a pipeline and a species/build";
        else
                check_pipeline $1;
                correct_pipeline=$?;
                check_genome $2;
                correct_species=$?;
                if [ "$correct_pipeline" == 0 ] && [ "$correct_species" == 0 ]
                then
                        #copy the pipeline, and change the standard values
#TODO
                        cat $BASEDIR/../pipelines/$1 | grep -v "##\[HELP\]" | grep -v "##\[CHANGE\]" | sed "s:##\[HOWTO\] ::g" > $1.howto;
                        for job in `grep "##\[JOB\]" $BASEDIR/../pipelines/$1 | sed 's:##\[JOB\]::g'`;
                        do
                                #copy the job to the job directory
                                copy_job $job $2;
                                IFS=$'\n';
                                #if extra changes are requered, do the extra changes
                                for change in `grep "##\[CHANGE\] $job" $BASEDIR/../pipelines/$1 | awk -v FS='\t' '{print $2;}'`;
                                do
                                        mv $job.pbs $job.tmp;
                                        echo "cat $job.tmp | $change > $job.pbs" | sh;
                                        rm $job.tmp;
                                done
                                unset IFS;
                                #insert the howto of the job into the howto of the pipeline
                                insertHowto=`grep "##\[HOWTO\]" $BASEDIR/../scripts/*/$job.pbs | sed "s:##\[HOWTO\] ::g" | awk '{printf $0"___";}'`;
                                cat $1.howto | sed "s<##\[JOB\] $job<${insertHowto}<g" | sed 's/___/\n/g'> $1.howto.tmp;
                                mv $1.howto.tmp $1.howto;
                        done
                        echo "Copied all jobs of the pipeline $1. Added the file $1.howto with the description on how to run this pipeline.";
                fi
        fi
}

