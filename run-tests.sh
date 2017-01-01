#!/bin/bash

# -----------------------------------------------------------------------------
# -- CONFIGURATION
# -----------------------------------------------------------------------------

# -- get BASEPATH
source ./config.cfg

# -- phpunit command
CMD="phpunit -c app/"


help () {
    echo -e "\n  $0 project [testsuite]\n"
    echo -e "      testsuite : testsuite name\n"
    exit 1
}

OPTIONS=false

while getopts ":p:vl" opt; do
    case $opt in
        v)
            HELP=true
            OPTIONS=true
        ;;
        l)
            LIST=true
            OPTIONS=true
        ;;
        p)
            if [ ! -r  $BASEPATH/$OPTARG ];
            then
                echo -e "\n  ERROR : project $1 not found or not readable in $BASEPATH/$OPTARG !\n"
                exit 1
            fi
            # -- store project name
            PROJECTNAME=$OPTARG

            # -- create project path
            PROJECTPATH=$BASEPATH/$PROJECTNAME

            OPTIONS=true
        ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
        ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
        ;;
    esac
done


shift $(expr $OPTIND - 1 )

if [[ $1 ]]; then
    TESTSUITE=$1
fi



if [[ $OPTIONS != "true" ]];
then
    help
fi


if [[ $HELP == "true" ]]; then
    help
fi


if [[ $LIST == "true" ]]; then

    if [[ $PROJECTNAME == "" ]];
    then
        echo -e "\n  option -l require -p \n"
        # help
        exit
    else
        cd $PROJECTPATH/htdocs
        # echo -e "\n  testsuites found in $PROJECTNAME\n"
        TESTSUITES=($(grep "testsuite name" app/phpunit.xml 2>/dev/null | cut -d\" -f2 ))

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


# -----------------------------------------------------------------------------
# -- VARIABLES
# -----------------------------------------------------------------------------



if [ $TESTSUITE ]; then
    CMD=$CMD' --testsuite '$TESTSUITE
    echo $CMD
fi


# cd $PROJECTPATH

recreate.sh $PROJECTNAME Tests

cd $PROJECTPATH/htdocs/

$CMD
