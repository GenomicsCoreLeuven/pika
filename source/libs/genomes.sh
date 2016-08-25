#!/bin/sh

show_genomes(){
	echo "#The list is: genome, build and combination to give to the jobs/pipeline";
	for species in `ls -1 -d $GENOMEDIR/* | sed "s:$GENOMEDIR/::g"`;
	do
		echo $species;	
		for build in `ls -1 -d $GENOMEDIR/$species/* | sed "s:$GENOMEDIR/$species/::g"`;
		do
			printf "%-20s  %-20s %-20s \n" "" "$build" "$species/$build";	
		done
	done	
}

check_genome(){
        correct=0;
        if [ $# -eq 0 ];
        then
                echo "No parameter given";
                correct=1;
        else
                #a  name is given
		if [[ "$1" =~ ^\/.* ]];
		then
			#alternative path to genome
			GENOMEDIR=$1;

		elif [[ "$GENOMEDIR" =~ .*$1$ ]];
		then
			#already correct path
			GENOMEDIR="$GENOMEDIR";
		else
			GENOMEDIR="$GENOMEDIR/$1";
		fi
                if [ `ls -1 -d $GENOMEDIR/ 2>/dev/null | wc -l` -eq 0 ];
                then
                        #name does not exists
                        echo "No genome and build found with this name: $GENOMEDIR";
                        correct=1;
                fi
                if [ `ls -1 -d $GENOMEDIR/ 2>/dev/null | wc -l` -gt 1 ];
                then
                        #multiple genomes for the name
                        echo "Multiple genomes and builds found with this name";
                        correct=1;
                fi
        fi
        return "$correct";
}
