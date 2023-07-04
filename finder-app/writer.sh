#!/bin/bash

writefile=$1
writestr=$2

if [ $# -ne 2 ]
then
	echo "Invalid Number of arguments"
	exit 1
fi

directory=$(dirname "${writefile}")


mkdir -p "${directory}" && echo "${writestr}" > $writefile



if [ ! -f "$writefile" ]
then
    echo "File could not be created."
    exit 1
fi

exit 0
