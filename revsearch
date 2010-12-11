#!/bin/bash
file="$1"
REVISIONS=`svn log $file -q --stop-on-copy |grep "^r" | cut -d"r" -f2 | cut -d" " -f1`
for rev in $REVISIONS; do
    prevRev=$(($rev-1))
    difftext=`svn diff --old=$file@$prevRev --new=$file@$rev | tr -s " " | grep -v " -\ \- " | grep -e "$2"`
    if [ -n "$difftext" ]; then
        echo "$rev: $difftext"
    fi
done
