## Data for Vanilla implementation of CNN 
## Need just two files. 
## File 1: Linked records (bug report text and source file text combined)
## File 2: Non-Linked records(same as above)

library(tm)
library(hash)
library(SnowballC)
library(textstem)
library(data.table)

swt <-dbConnect(MySQL(), user='root', password='Sravya010203', dbname='swt', host='localhost')
results<-dbSendQuery(swt,"SELECT bug_id,summary,description,files FROM bug_and_files ORDER BY report_time DESC")
res<-dbFetch(results,n=-1)
SWT<-as.data.frame(res)

SWT["combined_text"]<-paste(SWT$summary,SWT$description,sep=" ")

## expanding the files columns to make sure there is one file per row
SWT$files<-gsub("\\.java","\\.java<delim>",SWT$files)
s <- strsplit(SWT$files, split = "<delim>")
colnames(SWT)
SWT<-data.frame(bug_id= rep(SWT$bug_id, sapply(s, length)),combined_text = rep(SWT$combined_text, sapply(s, length)), files = unlist(s))
SWT$files<-as.character(SWT$files)
SWT$files<-trimws(SWT$files,which="both")


# Only linked file data
SWT_Linked_Files<-read.csv(file="/Volumes/CORSAIR/Results/SWT/SWT_Linked_file_data.txt",sep="\t",header = FALSE,
                              col.names=c("file","file_text"))
SWT_Linked_Files$file<-gsub("\\./","",SWT_Linked_Files$file)
SWT_Linked_Files$file<-trimws(SWT_Linked_Files$file,which="both")

# Removing all files which do not have any content in them. 
SWT_Linked_Files<-SWT_Linked_Files[!SWT_Linked_Files$file_text=="",]

## remove all test case related files
SWT_Linked_Files<-SWT_Linked_Files[!grepl("tests\\/", SWT_Linked_Files$file),]
SWT_Linked_Files<-SWT_Linked_Files[!grepl("testdata\\/", SWT_Linked_Files$file),]

#############################################################################################
#Make sure we have only the Linked Records Files and the actual files extracted from repo match

SWT<-SWT[SWT$files %in% SWT_Linked_Files$file,]
SWT_Files<-SWT_Linked_Files[SWT_Linked_Files$file %in% SWT$files,]
######################################## Text Pre-Processing #####################################################################
# Normalizing the source code text 
SWT_Files$file_text<-stem_strings(SWT_Files$file_text)
SWT_Files$file_text<- gsub('\\s+', ' ', SWT_Files$file_text)
SWT_Files$file_text<- gsub('^\\s+', '', SWT_Files$file_text)
SWT_Files$file_text<-trimws(SWT_Files$file_text,which="both")

# Normalizing the bug report text
SWT$combined_text<-gsub("[[:punct:]]"," ",SWT$combined_text)
SWT$combined_text<-gsub("[[:digit:]]"," ",SWT$combined_text)
SWT$combined_text<-gsub("([A-Z])", " \\1", SWT$combined_text)
SWT$combined_text<-gsub("(?<=\\b\\w)\\s(?=\\w\\b)", "",SWT$combined_text,perl=T)
SWT$combined_text<-tolower(SWT$combined_text)
SWT$combined_text<-stem_strings(SWT$combined_text)
SWT$combined_text<- gsub('\\s+', ' ', SWT$combined_text)
SWT$combined_text<- gsub('^\\s+', '', SWT$combined_text)

##################################################################################################

# Bug Ids and Bug Reports
dfBRRandom<-unique(SWT[sample(nrow(SWT)),c("bug_id","combined_text")])
#dfBRRandom$length <- nchar(as.character(dfBRRandom$combined_text))
#summary(dfBRRandom$length)

# Dump bug reports to file
write.table(dfBRRandom,file="~/Downloads/SWT_dfBR_Long.txt",sep="\t", row.names = FALSE, col.names = FALSE)

dfBRRandom<-read.csv(file="/Volumes/CORSAIR/Results/SWT/SWT_dfBR_Short.txt",sep="\t",header = FALSE,col.names = c("bug_id","combined_text"))

# Files and the extracted textual content from File
dfFileRandom<-SWT_Files[sample(nrow(SWT_Files)),]

distinct_file_names<-data.frame(files=dfFileRandom$file,file_text=dfFileRandom$file_text)
distinct_bug_reports<-data.frame(unique(dfBRRandom))

# 4151 bug reports
count_of_distinct_bug_reports <- length(unique(distinct_bug_reports$bug_id))

# 1414 linked files / buggy files
count_of_distinct_file_names <- nrow(distinct_file_names)

linked_data_tbl <- hash(keys = paste(SWT$files, SWT$bug_id,sep="#"), values = 0)

print(paste("Total Number of bug reports:",count_of_distinct_bug_reports))
print(paste("Total Number of source files:",count_of_distinct_file_names))

write.table(data.frame(),file="/Volumes/CORSAIR/Results/SWT/Buggy_Files/rt-polarity.neg",col.names = FALSE,row.names = FALSE,quote = FALSE)
write.table(data.frame(),file="/Volumes/CORSAIR/Results/SWT/Buggy_Files/rt-polarity.pos",col.names = FALSE,row.names = FALSE,quote = FALSE)
write.table(data.frame(bug_id=as.integer(),sentence=as.character()),file="/Volumes/CORSAIR/Results/SWT/Buggy_Files/bug_id_sentence",col.names = FALSE,row.names = FALSE,quote = FALSE)

cnt <- 1
for(i in 1:count_of_distinct_bug_reports){
  cat(paste("Processing bug report:",i,"\n"))
  bug_report_id<-distinct_bug_reports[i,1]
  bug_report_text<-distinct_bug_reports[i,2]
  start_id <- cnt
  end_id <- cnt + nrow(distinct_file_names) - 1
  dat <- data.frame(row_id = seq(start_id, end_id), bug_id = bug_report_id, bug_report_text = bug_report_text, file = distinct_file_names$files, 
                    file_text=distinct_file_names$file_text,class_label = "neg")
  
  #update class of linked records
  linked_rows_ids <- which(has.key(paste(dat$file, bug_report_id,sep = "#" ), linked_data_tbl))
  dat$class_label<-as.character(dat$class_label)
  dat$class_label[linked_rows_ids] = "pos"
  dat$sentence<-paste(dat$bug_report_text,dat$file_text,sep=" ")
  cnt <- end_id + 1
  
  #save data to positive and negative files
  
  pos_rows_to_append<-dat[dat$class_label=="pos","sentence"]
  neg_rows_to_append <-dat[dat$class_label=="neg","sentence"]
  tot_rows_to_append <-dat[,c("bug_id","sentence")]
  
  pos_file_path <- paste("/Volumes/CORSAIR/Results/SWT/Buggy_Files/","rt-polarity.pos", sep="")
  neg_file_path <- paste("/Volumes/CORSAIR/Results/SWT/Buggy_Files/","rt-polarity.neg", sep="")
  tot_file_path <- paste("/Volumes/CORSAIR/Results/SWT/Buggy_Files/","bug_id_sentence", sep="")
  
  write.table(pos_rows_to_append,file=pos_file_path, append=TRUE,row.names=FALSE,quote = FALSE,col.names =FALSE)
  write.table(neg_rows_to_append,file=neg_file_path, append=TRUE,row.names=FALSE,quote = FALSE,col.names =FALSE)
  write.table(tot_rows_to_append,file=tot_file_path, append=TRUE,row.names=FALSE,quote = FALSE,col.names =FALSE,sep="\t")
  
}



