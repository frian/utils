#!/bin/bash

# -----------------------------------------------------------------------------
# -- CONFIGURATION
# -----------------------------------------------------------------------------

# -- get BASEPATH
source ./config.cfg


# -- environment : Dev, Tests, Release
ENV=Dev


#
# -- check if argument, check if project folder exist -------------------------
#
if [ ! $1 ];
then
    echo -e "\n  usage : $0 project [Dev|Tests|Release]\n"
    exit 1
else
    if [ ! -r  $BASEPATH/$1 ];
    then
        echo -e "\n  ERROR : project $1 not found or not readable in $BASEPATH/$1 !\n"
        exit 1
    fi
fi

if [[ $2 == "Tests" || $2 == "Release" || $2 == "Dev" ]];
then
    ENV=$2
else
    echo -e "\n  ERROR : wrong parameter $2 !\n"
    exit 1
fi


# -----------------------------------------------------------------------------
# -- VARIABLES
# -----------------------------------------------------------------------------

# -- store project name
PROJECTNAME=$1

# -- create project path
PROJECTPATH=$BASEPATH/$PROJECTNAME


echo -e "\nrecreating $PROJECTNAME project \n"

#
#  -- cd into project htdocs folder --
#
echo -n "  cd into htdocs ... "
cd $PROJECTPATH/htdocs
echo done


echo -n "  delete db ... "
app/console doctrine:database:drop --force 1>/dev/null
echo done


echo -n "  create db ... "
app/console doctrine:database:create 1>/dev/null
echo done


echo -n "  create schema ... "
app/console doctrine:schema:create 1>/dev/null
echo done


echo -e "  loading fixtures ... \n"
app/console -n doctrine:fixtures:load --fixtures=src/TimeTM/CoreBundle/DataFixtures/ORM/$ENV/
echo -e "\n  done"


echo -e "\ndone \n"
