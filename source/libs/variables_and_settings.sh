#!/bin/sh

check_config_file(){
	if [ -f ~/.pika_config ];
	then
		echo "Config file found. This is the content:";
		set_mail $MAIL;
		set_billing;
		echo "Standard mail: $MAIL";
		echo "Standard billing: $BILLING";
		echo "Standard genome path: $GENOMEDIR";
		echo "Standard extra modules command: $EXTRA_MODULES";
		echo "Standard module version: $MODULE_VERSION";
	else
		echo "No config file found";
		echo -n "Do you want to create a config file [y/n]: ";
		read -n 1 tocreate;
		echo "";
		case "$tocreate" in
			y)
				change_config;
			;;
		esac
	fi
}

set_mail(){
	if [ -f ~/.pika_config ];
        then
		MAIL=`grep "mail=" ~/.pika_config | awk -v FS="=" '{print $2;}'`;
	else
		MAIL="";
	fi
}

set_billing(){
        if [ -f ~/.pika_config ];
        then
                BILLING=`grep "billing=" ~/.pika_config | awk -v FS="=" '{print $2;}'`;
        else
                BILLING="default_project";
	fi
}

set_extra_modules(){
	if [ -f ~/.pika_config ];
	then
		EXTRA_MODULES=`grep "extra_modules=" ~/.pika_config | awk -v FS="=" '{print $2;}'`;
	else
		EXTRA_MODULES="";
	fi
}

set_module_version(){
	if [ -f ~/.pika_config ];
	then
		MODULE_VERSION=`grep "module_version=" ~/.pika_config | awk -v FS="=" '{print $2;}'`;
	else
		MODULE_VERSION="";
	fi
}

change_config(){
	#create a config file
	touch ~/.pika_config;
        echo -n "Please insert your mail adress [current: $MAIL]: ";
        read mail;
        echo -n "Please insert the default billing account [current: $BILLING]: ";
        read billing;
        echo "Please insert the default genome directory [current: $GENOMEDIR]: ";
        read genomedir;
	echo -n "Please insert your Extra Modules Command [current: $EXTRA_MODULES]: ";
	read extramodules;
	echo -n "Please insert the to use module version [current: $MODULE_VERSION]: ";
	read moduleversion;
	if [ "$mail" != "" ]
	then  
        	echo "mail=$mail" > ~/.pika_config;
		MAIL=$mail;
	else
		echo "mail=$MAIL" > ~/.pika_config;
	fi
	if [ "$billing" != "" ]
	then
        	echo "billing=$billing" >> ~/.pika_config;
		BILLING=$billing;
	else
		echo "billing=$BILLING" >> ~/.pika_config;
	fi
	if [ "$genomedir" != "" ]
	then
		echo "genomes=$genomedir" >> ~/.pika_config;
		GENOMEDIR=$genomedir;
	else
		echo "genomes=$GENOMEDIR" >> ~/.pika_config;
	fi
	if [ "$extramodules" != "" ]
	then
		echo "extra_modules=$extramodules" >> ~/.pika_config;
		EXTRA_MODULES=$extramodules;
	else
		echo "extra_modules=$EXTRA_MODULES" >> ~/.pika_config;
	fi
	check_module_exists $moduleversion;
	correct_module=$?;
	if [ "$moduleversion" != "" ]  && [ "$correct_module" != 0 ] && [ "$moduleversion" != "non" ]
	then
		echo "The given module version does not exists, module version not changed";
		moduleversion="";
	fi
	if [ "$moduleversion" != "" ] && [ "$moduleversion" != "non" ]
	then
		echo "module_version=$moduleversion" >> ~/.pika_config;
		MODULE_VERSION=$moduleversion;
	else
		if [ "$moduleversion" == "non" ]
		then
			MODULE_VERSION="";
		fi
		echo "module_version=$MODULE_VERSION" >> ~/.pika_config;
	fi
	echo "New config file saved";
}

set_jobs_dir(){
	curdir=`pwd`;
	if [ "$(basename $curdir)" != "jobs" ];
	then
		#job dir has to be created 
		PROJECT_DIR=`pwd`;
		mkdir -p jobs;
		cd jobs;
		JOBDIR=`pwd`;
	else
		#already in job dir, set projectdir
		PROJECT_DIR=$(dirname $curdir);
		JOBDIR=`pwd`;
	fi
}

set_genome_dir(){
        if [ -f ~/.pika_config ];
        then
                GENOMEDIR=`grep "genomes=" ~/.pika_config | awk -v FS="=" '{print $2;}'`;
        else
                GENOMEDIR="~";
        fi
}

