declare -A ENGINE_NAME_ARRAY;
declare -A ENGINE_VALUE_ARRAY;

show_engine(){
	enginedir="$BASEDIR/../engines/";
	for name in `ls -1 -d $enginedir* | sed "s:$enginedir::g"`;
	do
		echo $name;
	done
}

check_engine_exists(){
	correct_engine=0;
	if [ $# -eq 0 ];
	then
		#echo "No parameter given";
		correct_engine=1;
	else
		#a engine is given
		if [ `ls -1 -d $BASEDIR/../engines/$1 2>/dev/null | wc -l` -eq 0 ];
		then
			#engine does not exists
			echo "No engine found with this name";
			correct_engine=1;
		fi
		if [ `ls -1 -d $BASEDIR/../engines/$1 2>/dev/null | wc -l` -gt 1 ];
		then
			#multiple engines for the name
			echo "Multiple engines found with this name";
			correct_engine=1;
		fi
	fi
	return "$correct_engine";
}

script_to_engine(){
	script=$1;
	cp $BASEDIR/../engines/$GRID_ENGINE $script.header;
	declare -A engine_script_array;
	while read line
	do
		if [[ $line == *"##[RUN]"* ]]
		then
			key=`echo $line | awk '{print $2;}'`;
			value=`echo $line | awk '{print $3;}'`;
			engine_script_array["$key"]="$value";
		fi
	done < $script;
	engine_script_array["SECONDS"]=`echo ${engine_script_array["WALLTIME"]} | awk -v FS=":" '{tot=0; for(i=1; i<=NF; i++){tot=((tot*60) + $i)} print tot;}'`;
	engine_script_array["TOTAL_CORES"]=$((${engine_script_array["NODES"]} * ${engine_script_array["CORES_PER_NODE"]}));
	params=("WALLTIME" "MEMORY" "TOTAL_CORES" "NAME" "NODES" "CORES_PER_NODE" "PARTITION" "SECONDS");
	arrayContainsElement "MEMTYPE" "${ENGINE_NAME_ARRAY[@]}";
	memtype=$?;
	if [ "$memtype" == 0 ];
	then
		if [ "${ENGINE_VALUE_ARRAY["MEMTYPE"]}" == "UPPER" ];
		then
			engine_script_array["MEMORY"]=`echo ${engine_script_array["MEMORY"]} | sed 's:gb:G:g' | sed 's:mb:M:g' | sed 's:GB:G:g' | sed 's:MB:M:g'`;
		else
			engine_script_array["MEMORY"]=`echo ${engine_script_array["MEMORY"]} | sed 's:G:gb:g' | sed 's:M:mb:g' | sed 's:GB:gb:g' | sed 's:MB:mb:g'`;
		fi
	fi
	for i in ${params[@]};
	do
		if [ "${engine_script_array[$i]}" == "" ];
		then
			grep -v "$i" $script.header > $script.header.tmp;
		else
			sed "s/$i/${engine_script_array[$i]}/" $script.header > $script.header.tmp;
		fi
		mv $script.header.tmp $script.header;
	done
	jobid="${ENGINE_VALUE_ARRAY["job_id"]}";
	grep -v "##\[RUN\]" $script | grep -v "#!/bin/bash" | sed "s:JOBID=\"\";:JOBID=$jobid;:" >> $script.header;
	mv $script.header $script;
}


set_grid_parameters(){
	engine_param_count=0;
	oldIFS=$IFS;
	IFS='';
	while read -r line;
	do
		name=`echo $line | awk '{print $1}'`;
		value=`echo $line | awk -v FS='\t' '{print $2}'`;
		ENGINE_NAME_ARRAY[$engine_param_count]=$name;
		ENGINE_VALUE_ARRAY["$name"]="$value";
		((engine_param_count++));
	done < $BASEDIR/../engines/$GRID_ENGINE".setup";
	extention=${ENGINE_VALUE_ARRAY["extention"]};
	IFS=$oldIFS;
}



