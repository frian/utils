#!/bin/bash

#
# -- get and cd in script dir for config sourcing
#

# -- Absolute path to this script
SCRIPT=$(readlink -f "$0")

# -- Absolute path to script dir
SCRIPTPATH=$(dirname "$SCRIPT")

# -- cd to script dir for config sourcing
cd $SCRIPTPATH


# -----------------------------------------------------------------------------
# -- CONFIGURATION
# -----------------------------------------------------------------------------

# -- get BASEPATH
source ./config.cfg

# -- phpunit command
CMD="phpunit -c app/"


# -----------------------------------------------------------------------------
# -- FUNCTIONS
# -----------------------------------------------------------------------------

help () {
    echo -e "\n  $0 [ -l -h ] -p project [testsuite]\n"
    echo -e "      -l : list testsuites in a project\n"
    echo -e "      -h : help\n"
    exit 1
}

# -----------------------------------------------------------------------------
# -- VARIABLES
# -----------------------------------------------------------------------------

OPTIONS=false


#
# .-- handle options ----------------------------------------------------------
#
#       -h : show help and usage
#       -p : project name
#       -l : list testsuites for a given project
#
while getopts ":p:hl" opt; do
    case $opt in
        h)
            help
        ;;
        l)
            # -- set list flag
            LIST=true

            # -- set options flag
            OPTIONS=true
        ;;
        p)
            # -- check if project folder exist, if not throw error
            if [ ! -r  $BASEPATH/$OPTARG ];
            then
                echo -e "\n  ERROR : project $OPTARG not found or not readable in $BASEPATH/$OPTARG !\n"
                exit 1
            fi

            # -- set project flag
            PROJECT=true

            # -- store project name
            PROJECTNAME=$OPTARG

            # -- create project path
            PROJECTPATH=$BASEPATH/$PROJECTNAME

            # -- set options flag
            OPTIONS=true
        ;;
        \?)
            # -- invalid option
            echo "  invalid option: -$OPTARG" >&2
            exit 1
        ;;
        :)
            # -- missing argument
            echo "  option -$OPTARG requires an argument." >&2
            exit 1
        ;;
    esac
done


# -- if no option is set show help
if [[ $OPTIONS != "true" ]];
then
    help
fi


# -- get next argument
shift $(expr $OPTIND - 1 )

# -- if argument set as testsuite name
if [[ $1 ]];
then
    TESTSUITE=$1
fi


# -----------------------------------------------------------------------------
# -- START
# -----------------------------------------------------------------------------

# -- cd in project htdocs
cd $PROJECTPATH/htdocs

#
# -- handle list action -------------------------------------------------------
#
if [[ $LIST == "true" ]]; then

    #
    # -- if project is not defined, show error and exit
    #
    if [[ $PROJECT != "true" ]];
    then
        echo -e "\n  option -l require -p \n"
        # help
        exit
    else
        # -- get testsuites
        TESTSUITES=($(grep "testsuite name" app/phpunit.xml 2>/dev/null | cut -d\" -f2 ))

        # -- output
        if [[ ${#TESTSUITES[@]} -eq  0 ]]; then
            echo -e "\n  no testsuite found in $PROJECTNAME\n"
        else
            echo -e "\n  testsuites found in $PROJECTNAME\n"
            for testsuite in ${TESTSUITES[@]}
            do
                echo "    "$testsuite
            done
            echo
        fi

        exit 0
    fi
fi


#
# -- run tests ----------------------------------------------------------------
#

# -- if testsuite append to command
if [ $TESTSUITE ]; then
    CMD=$CMD' --testsuite '$TESTSUITE
fi

# -- recreate project with Tests fixtures
recreate.sh $PROJECTNAME Tests

# -- run phpunit
$CMD

# done
