while read line; do echo $line; git checkout $line~1; head=$(git rev-parse --short HEAD~1); echo "$head,$line" >> head_commit.out; git checkout master; done < eclipse_commits_filtered.csv
