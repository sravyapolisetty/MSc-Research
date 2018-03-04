#!/bin/bash

set -e

if [ $# -eq 0 ]
then
    srcs="."
else
    srcs="$@"
fi

function ignore_comments() {
    cpp | grep -Evx '#.+'
}

# Ignore import and package statements because package names are based on DNS names not domain terminology
function ignore_package_names() {
    grep -Evx '[[:space:]]*(import|package)[[:space:]].+'
}

#function ignore_copyright(){
	#sed -E '/(Copyright)/,/([*]\/)/d'
#}

# -exec cat works with paths that contain spaces, while pipe through xargs cat does not
find $srcs -name '*.java' -exec cat {} \; | ignore_comments | ignore_package_names
#find "$srcs" -name '*.java' -exec cat {} \; 



