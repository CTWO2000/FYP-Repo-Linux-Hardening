#!/bin/bash 

if [ -L $0 ] ; then
    DIR=$(dirname $(readlink -f $0)) ;
else
    DIR=$(dirname $0) ;
fi ;

echo $DIR
#PWD=$(pwd)


#mkdir $DIR/test2
