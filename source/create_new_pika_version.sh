#!/bin/sh
VERSION="pika 17.01 dev";
#BASEDIR=$(dirname $0);
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";



if [ "$#" -eq 0 ]
then
    echo "You must give an version number.";
else
    VERSION=$1;
    echo -n "Are you sure you want to make a new version with the name: $VERSION? [y/n]";
    read a;
    if [ $a != "y" ];
    then
        exit;
    fi;
    #check if already exists
    tmp=$(ls -1 -d $BASEDIR/../*/$VERSION 2>&1);
    exists=$?;
    if [ $exists == 0 ];
    then
        #version already exists
        echo "This version already exists, please give another name";
        exit;
    fi
    #go over every content in the directory
    for i in `ls -1 $BASEDIR/..`; 
    do 
        #check if it is a directory
        if [[ -d $BASEDIR/../$i ]]; 
        then 
            #check if pikaDEV exists
            if [[ -f $BASEDIR/../$i/pikaDEV ]]; 
            then 
                #check the files
                cp $BASEDIR/../$i/pikaDEV $BASEDIR/../$i/$VERSION;
            elif [[ -d $BASEDIR/../$i/pikaDEV ]];
            then
                #check the directories
		cp -r $BASEDIR/../$i/pikaDEV $BASEDIR/../$i/$VERSION;
                #change the version in the pipelines dir
                if [[ $i == "pipelines" ]];
                then
                    for pipeline in `ls -1 $BASEDIR/../$i/$VERSION`;
                    do
                        #go over every pipeline
                        cat $BASEDIR/../$i/$VERSION/$pipeline | sed "s/##\[VERSION\].*/##\[VERSION\] $VERSION/g" > $BASEDIR/../$i/$VERSION/$pipeline".tmp";
                        mv $BASEDIR/../$i/$VERSION/$pipeline".tmp" $BASEDIR/../$i/$VERSION/$pipeline;
                    done
                    chmod 775 -R $BASEDIR/../$i/$VERSION;
                fi;
                #change the version in the scripts dir
                if [[ $i == "scripts" ]];
                then
                    for scriptType in `ls -1 $BASEDIR/../$i/$VERSION`;
                    do
                        #go over every script
                        for script in `ls -1 $BASEDIR/../$i/$VERSION/$scriptType`;
                        do
                            cat $BASEDIR/../$i/$VERSION/$scriptType/$script | sed "s/##\[VERSION\].*/##\[VERSION\] $VERSION/g" > $BASEDIR/../$i/$VERSION/$scriptType/$script".tmp";
                            mv $BASEDIR/../$i/$VERSION/$scriptType/$script".tmp" $BASEDIR/../$i/$VERSION/$scriptType/$script;
                        done
                    done
                    chmod 775 -R $BASEDIR/../$i/$VERSION;
                fi
            fi; 
        fi; 
    done
    cat pika.sh | sed "s/VERSION=.*/VERSION=\"$VERSION\"/g" > pika.sh.tmp;
    mv pika.sh.tmp pika.sh;
    cat pikasub.sh | sed "s/VERSION=.*/VERSION=\"$VERSION\"/g" > pikasub.sh.tmp;
    mv pikasub.sh.tmp pikasub.sh;
    chmod 775 pika.sh;
    chmod 775 pikasub.sh;


fi







