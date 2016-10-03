
show_modules(){
        moduledir="$BASEDIR/../modules/";
	for name in `ls -1 -d $moduledir* | sed "s:$moduledir::g"`;
        do
                echo $name;
        done
}


check_module_exists(){
        correct_module=0;
        if [ $# -eq 0 ];
        then
                #echo "No parameter given";
                correct_module=1;
        else
                #a module is given
                if [ `ls -1 -d $BASEDIR/../modules/$1 2>/dev/null | wc -l` -eq 0 ];
                then
                        #module does not exists
                        echo "No module version found with this name";
                        correct_module=1;
                fi
                if [ `ls -1 -d $BASEDIR/../modules/$1 2>/dev/null | wc -l` -gt 1 ];
                then
                        #multiple modules for the name
                        echo "Multiple modules found with this name";
                        correct_module=1;
                fi
        fi
        return "$correct_module";
}

load_modules(){
	check_module_exists $MODULE_VERSION;
	exists=$?;
	if [ "$exists" == 0 ]
	then
		module_count=0;
		while read line; 
		do
			key=`echo $line | awk '{print $1}'`;
			value=`echo $line | awk '{print $2}'`;
			MODULE_NAME_ARRAY[$module_count]=$key;
			MODULE_VERSION_ARRAY[$key]=$value;
			((module_count++));
		done < $BASEDIR/../modules/$MODULE_VERSION;
	fi
}








