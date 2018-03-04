#!/bin/bash
while read line
do
    head=$(echo $line | awk -F\, '{print $1}') 
    commit=$(echo $line | awk -F\, '{print $2}')
    while read newline
    do
        type=$(echo "$newline" | cut -f 1)
        file=$(echo "$newline" | cut -f 2)
        if [[ $type == "A" ]] || [[ $type == "M" ]]; then
            git checkout $commit
            if [ -f "$file" ] && [ -e "$file" ]; then
                folder=${file%/*}
                [ ! -d "$HOME/Sravya_Backup/Eclipse_Repo_NewMap/$folder" ] && \
                    mkdir -p "$HOME/Sravya_Backup/Eclipse_Repo_NewMap/$folder"
                echo "$file exists in $commit"
                cp "$file" "$HOME/Sravya_Backup/Eclipse_Repo_NewMap/$folder"
            else
                echo "$file doesn't exist in $commit"
            fi
            git fetch --all && git reset --hard origin/master && git checkout master
            
        elif [[ $type == "D" ]]; then
            git checkout $head
            if [ -f "$file" ] && [ -e "$file" ]; then
                folder=${file%/*}
                [ ! -d "$HOME/Sravya_Backup/Eclipse_Repo_NewMap/$folder" ] && \
                    mkdir -p "$HOME/Sravya_Backup/Eclipse_Repo_NewMap/$folder"
                echo "$file exists in $commit"
                cp "$file" "$HOME/Sravya_Backup/Eclipse_Repo_NewMap/$folder"
            else
                echo "$file doesn't exist in $commit"
            fi
            git fetch --all && git reset --hard origin/master && git checkout master
         fi
     done < $commit.out
done < head_commit.out
