#!/bin/sh

check_config_file(){
	if [ -f $VSC_HOME/.pika_config ];
	then
		echo "Config file found. This is the content:";
		set_mail $MAIL;
		set_billing;
		echo "Standard mail: $MAIL";
		echo "Standard billing: $BILLING";
		echo "Standard genome path: $GENOMEDIR";
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
	if [ -f $VSC_HOME/.pika_config ];
        then
		MAIL=`grep "mail=" $VSC_HOME/.pika_config | awk -v FS="=" '{print $2;}'`;
	else
		MAIL="";
	fi
}

set_billing(){
        if [ -f $VSC_HOME/.pika_config ];
        then
                BILLING=`grep "billing=" $VSC_HOME/.pika_config | awk -v FS="=" '{print $2;}'`;
        else
                BILLING="default_project";
	fi
}

change_config(){
	#create a config file
	touch $VSC_HOME/.pika_config;
        echo -n "Please insert your mail adress [current: $MAIL]: ";
        read mail;
        echo -n "Please insert the default billing account [current: $BILLING]: ";
        read billing;
        echo "Please insert the default genome directory [current: $GENOMEDIR]: ";
        read genomedir;
	if [ "$mail" != "" ]
	then  
        	echo "mail=$mail" > $VSC_HOME/.pika_config;
		MAIL=$mail;
	else
		echo "mail=$MAIL" > $VSC_HOME/.pika_config;
	fi
	if [ "$billing" != "" ]
	then
        	echo "billing=$billing" >> $VSC_HOME/.pika_config;
		BILLING=$billing;
	else
		echo "billing=$BILLING" >> $VSC_HOME/.pika_config;
	fi
	if [ "$genomedir" != "" ]
	then
		echo "genomes=$genomedir" >> $VSC_HOME/.pika_config;
		GENOMEDIR=$genomedir;
	else
		echo "genomes=$GENOMEDIR" >> $VSC_HOME/.pika_config;
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
        if [ -f $VSC_HOME/.pika_config ];
        then
                GENOMEDIR=`grep "genomes=" $VSC_HOME/.pika_config | awk -v FS="=" '{print $2;}'`;
        else
                GENOMEDIR="$VSC_DATA";
        fi
}

