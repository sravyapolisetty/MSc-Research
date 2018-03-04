#!/bin/bash
while read line
do
echo $line
head=$(echo $line | awk -F\, '{print $1}')
commit=$(echo $line | awk -F\, '{print $2}')
files=()
files=$(git diff --name-status $head $commit | grep ".java$" | grep -E "^A|^M|^D")
#echo -ne ${files[@]} >> $commit.out
printf '%s\n' "${files[@]}" >> $commit.out
done < head_commit.out
