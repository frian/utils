#!/bin/bash


# -----------------------------------------------------------------------------
# -- CONFIGURATION
# -----------------------------------------------------------------------------

# -- web projects base path
BASEPATH=$HOME/atinfo/www

# -- suffix for the deployement site
DEPLOYSUFFIX="-deploy"

# -- printf output format
FORMAT="%-50s"

# -- timestamp for archive name
TIMESTAMP=`date +%Y%m%d_%H%M%S`


#
# -- check if argument, check if project folder exist -------------------------
#
if [ ! $1 ];
then
    echo -e "\n  usage : $0 project\n"
    exit 1
else
    if [ ! -r  $BASEPATH/$1 ];
    then
        echo -e "\n  ERROR : project $1 not found or not readable in $PROJECTPATH !\n"
        exit 1
    fi
fi


# -----------------------------------------------------------------------------
# -- VARIABLES
# -----------------------------------------------------------------------------

# -- store project name
PROJECTNAME=$1

# -- create project path
PROJECTPATH=$BASEPATH/$PROJECTNAME

# -- create deployment path
DEPLOYTPATH=$PROJECTPATH$DEPLOYSUFFIX/htdocs

# -- archive name
ARCHIVE=$PROJECTNAME-$TIMESTAMP.tgz

# -- run as normal user
RUNASUSER="sudo -u $(logname)"


# -----------------------------------------------------------------------------
# -- FUNCTIONS
# -----------------------------------------------------------------------------
function create_db {

    printf $FORMAT "  delete db ..."
    $RUNASUSER app/console doctrine:database:drop --force 1>/dev/null
    echo done

    printf $FORMAT "  create db ..."
    $RUNASUSER app/console doctrine:database:create 1>/dev/null
    echo done

    printf $FORMAT "  create schema ..."
    $RUNASUSER app/console doctrine:schema:create 1>/dev/null
    echo done

    printf $FORMAT "  loading fixtures ..."
    $RUNASUSER app/console doctrine:fixtures:load --no-interaction --fixtures=src/TimeTM/CoreBundle/DataFixtures/ORM/Dev/ 1>/dev/null
    echo done
}


#
#  -- check if root --
#
if [ "$(id -u)" != "0" ]; then
	echo -e "\n  please run with sudo\n"
	exit 1
fi


# -----------------------------------------------------------------------------
# -- CREATE RELEASE
# -----------------------------------------------------------------------------
echo -e "\ncreating $PROJECTNAME release\n"

#
#  -- cd into project folder --
#
cd $PROJECTPATH


#
#  -- create build, copy files and cd build -----------------------------------
#
#  -- PATH : $PROJECTPATH
#
printf $FORMAT "  create build folder ..."
$RUNASUSER mkdir build
echo done

printf $FORMAT "  copy htdocs into build ..."
$RUNASUSER cp -r htdocs/* build
echo done


#
#  -- run doctrine commands from htdocs ---------------------------------------
#
#  -- PATH : $PROJECTPATH/htdocs
#
printf $FORMAT "  cd into htdocs ..."
cd htdocs
echo done

create_db


#
#  -- clean cache and logs ----------------------------------------------------
#
#  -- PATH : $PROJECTPATH/build
#
printf $FORMAT "  cd into build ..."
cd ../build
echo done

printf $FORMAT "  clean app/cache ..."
rm -rf app/cache/*
echo done

printf $FORMAT "  clean app/logs ..."
rm -rf app/logs/*
echo done

printf $FORMAT "  reset permissions on cache and logs ..."
chmod -R 777 app/cache app/logs
echo done


#
#  -- delete parameters.yml, create archive
#
#  -- PATH : $PROJECTPATH/build
#
printf $FORMAT "  deleting parameters.yml ..."
rm app/config/parameters.yml
echo done

printf $FORMAT "  set .htaccess to prod ..."
$RUNASUSER sed -i 's/app_dev\.php/app\.php/' web/.htaccess
echo done

printf $FORMAT "  creating archive ..."
$RUNASUSER tar cfz ../$ARCHIVE *
echo done


#
#  -- cleaning ----------------------------------------------------------------
#
#  -- PATH : $PROJECTPATH
#
printf $FORMAT "  cd into timetm ..."
cd ..
echo done

printf $FORMAT "  deleting build folder ..."
rm -rf build
echo done

echo -e "\ndone \n\n"


# -----------------------------------------------------------------------------
# -- TESTING RELEASE
# -----------------------------------------------------------------------------
echo -e "testing $PROJECTNAME release\n"


#
#  -- cleaning deployment site, copy archive ----------------------------------
#
#  -- PATH : $PROJECTPATH
#
printf $FORMAT "  clean deploy site ..."
rm -rf $DEPLOYTPATH/*
echo done

printf $FORMAT "  copy archive to deploy site ..."
cp $ARCHIVE $DEPLOYTPATH
echo done

printf $FORMAT "  cd to deploy site ..."
cd $DEPLOYTPATH
echo done


#
#  -- extract archive, set permissions ----------------------------------------
#
#  -- PATH : $DEPLOYTPATH
#
printf $FORMAT "  extract archive ..."
tar xfz $ARCHIVE
echo done

printf $FORMAT "  set permissions on cache and logs ..."
chmod -R 777 app/cache app/logs
echo done


#
#  -- copy parameters.yml, set deploy db --------------------------------------
#
#  -- PATH : $DEPLOYTPATH
#
printf $FORMAT "  copy parameters.yml ..."
cp $PROJECTPATH/htdocs/app/config/parameters.yml app/config/
echo done

printf $FORMAT "  set database to deploy ..."
$RUNASUSER sed -i 's/timetm/timetm-deploy/' app/config/parameters.yml
echo done


#
#  -- run doctrine commands in deployment site --------------------------------
#
#  -- PATH : $DEPLOYTPATH
#
create_db


#
#  -- run phpunit tests --------------------------------
#
#  -- PATH : $DEPLOYTPATH
#
echo -e "  running tests :\n"
phpunit -c app/
echo "  testing done"


# -- end
