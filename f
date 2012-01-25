#!/bin/bash
## Find script - a quick script to lookup (find+grep)through my source code
# arguments:
#  -p: path to lookup in, if ommited looks:
#                           1. in the script or ENV FIND_PATH variable
#                           2. in your current location
#  -n: name regex, matches what you would put in a name argument to find command, except that it adds a * on both sides
#  -t: type, refers to the file extension, if ommited all files are searched, works together with the -n command
#  -e: expression, refers to the expression to find. put here what you would put in a egrep regexp
#  -c: count only - counts the number of occurances
# This is enough to satisfy my needs. Examples of my usage here (FIND_PATH is set to my current working git repo):
#   Find all the "table" entries in my css files
#   'f -t css -e table'
#       :expands to 'find . -type f -iname "*.css" -exec grep -niH "table" {} \;'
#  Find how many jars I have with "scanner" as part of its name
#   'f -n scanner -t jar -c'
#       :expands to 'find . -iname "*scanner*.jar" | wc -l'
#  Find in another path all occurences of javascript files where the setOptions function is defined
#   'export FIND_PATH=/opt/repo f -n toolbar -t js -e "function setOptions"'
#       :expands to 'find /opt/repo -type f -iname "*toolbar*.js" -exec grep -niH "setOptions" {} \;'
###########################
# Variables
# FIND_PATH - optional and can be set up in env as well. Default is none, uncomment to use my version.
#FIND_PATH='/opt/repo'
# Executable - find executable if not available in PATH, same for wc
FIND_EXE='/usr/bin/find'
WC_EXPR='/usr/bin/wc -l'
FIND_ARGS=
NAME_ARG=
TYPE_ARG=
EXPRESSION=
COUNT=0
###########################
# Functions
# createpath - if FIND_PATH does not exist, './' is used. If FIND_PATH exists (or is set via -p), use that
# Takes one optional argument (path to search)
function createpath {
    if [ -z $1 ]; then
        FIND_PATH=`pwd` # if no argument is passed, we set the var to current path
    fi
    if [ -e $1 ]; then
        FIND_ARGS="$FIND_PATH"   # double quotes to avoid escaping our variable
    else
        FIND_ARGS='.' # find in local dir if no path or incorrect path
    fi
    echo Searching in $FIND_ARGS
}
#
###########################
# Script execution
# First, parse arguments. Looking for -p (path), -n (name), -t (type) -e (expression) -c (count)
# We will set the expression to whatever we got without arguments. If we got a -e arg, we can ignore this
# TODO: parse all non-option args into search expression
while getopts "p:n:t:e:c" opt
do
    case $opt in
        p)      # PATH - lets set it
            FIND_PATH="$OPTARG"
            echo "Creating path from $FIND_PATH"
            createpath $FIND_PATH
        ;;
        n)      #name arg
            NAME_ARG="*$OPTARG*"
        ;;
        t)      # file type
            #TODO parse dot. for now leave as is
            TYPE_ARG="$OPTARG"
        ;;
        e)
            EXPRESSION="$OPTARG"
        ;;
        c)  # -c called, we need to append the count command
            COUNT=1
        ;;
    esac
done
# assemble command from $FIND_PATH $NAME_ARG $TYPE_ARG $EXPRESSION $COUNT
# We have the path, at least the default
FIND_EXE="$FIND_EXE $FIND_PATH"
# do we have name arguments for find command?
if [ -z $NAME_ARG ]; then
    if [ -z $TYPE_ARG ]; then
        # no name command to append
        FIND_EXE="$FIND_EXE"
    else
        FIND_EXE="$FIND_EXE -name \"*$TYPE_ARG\""
    fi
else
    if [ -z $TYPE_ARG ]; then
        FIND_EXE="$FIND_EXE -name \"$NAME_ARG\""
    else
        FIND_EXE="$FIND_EXE -name \"$NAME_ARG$TYPE_ARG\""
    fi
fi
echo stage 2: $FIND_EXE
# if no expression to search for, just search all the files
if [ -z $EXPRESSION ]; then
    # count or not?
    if [ $COUNT -eq 0 ]; then
        FIND_EXE="$FIND_EXE"
    else
        FIND_EXE="$FIND_EXE | $WC_EXPR"
    fi
else
    if [ $COUNT -eq 0 ]; then
       FIND_EXE="$FIND_EXE -exec grep -niH \"$EXPRESSION\" {} \;"
    else        
        FIND_EXE="$FIND_EXE -exec grep -niH \"$EXPRESSION\" {} \; | $WC_EXPR"
    fi
fi
# echo "The final command is $FIND_EXE"
eval $FIND_EXE
