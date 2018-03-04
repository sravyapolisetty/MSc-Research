#step1 run python data.py <missing bug file> <new file>
import csv, sys, os
file = os.path.join(sys.path[0], sys.argv[1])
newfile = os.path.join(sys.path[0], sys.argv[2])
print os.path.join(sys.path[0], file)
print os.path.join(sys.path[0], newfile)
with open(file, "rb") as csvfile:
    reader =  csv.reader(csvfile, delimiter=",")
    for row in reader:
        data = ([row[1]],row[2].split("\r\n"))
        with open(newfile, "a+") as newcsvfile:
            writedata = csv.writer(newcsvfile)
            writedata.writerows(data)

# step 2 open new file in vi or vim and run ":%normal J" to merge every other line in vim
