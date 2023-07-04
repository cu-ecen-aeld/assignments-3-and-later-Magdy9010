#string!/bin/sh 
filesdir=$1
searchstr=$2
compstr=linux
X=0  #number of files
Y=0 #number of lines


if [ $# -ne 2 ]

then 
	echo "Invalid number of arguments" 
	exit 1
fi

if [ ! -d "$filesdir" ]

then
	echo "Invalid Directory -- Doesn't exist"
	exit 1
fi

#============================================================
#===========================================================
X=$(grep -r -l $searchstr $filesdir|wc -l)
Y=$(grep -r $searchstr $filesdir|wc -l)

echo "The number of files are ${X} and the number of matching lines are ${Y}"

exit 0