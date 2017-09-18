#!/bin/bash

SBASE="/home/sites"
OLDDIR="`pwd`"

cd $SBASE
for site in *
do
    echo "Processing $site ... "
    find $SBASE/$site/pub/sessions -type f -exec rm -v {} \;
    find $SBASE/$site/pub/tmp -type f -exec rm -v {} \;
    echo "done"
    
done
cd $OLDDIR

# eof
