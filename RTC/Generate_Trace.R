## Run this on ENG server 
### For generating non-links as suggested by Dr.Andriy

set.seed(12345) #for reproducability

#not for server but for local machine
#linked_data<-df5
#saveRDS(linked_data,file="~/Desktop/dfLinked.rds")


linked_data<-readRDS(file="/home/spoliset/dfLinked.rds")
dfWIRandom<-readRDS(file="/home/spoliset/dfWIRandom.rds")
dfTCRandom<-readRDS(file="/home/spoliset/dfTCRandom.rds")


linked_data$Source_Code_File<-gsub("[^[:alnum:]]"," ",linked_data$Source_Code_File)
linked_data$Source_Code_File<-gsub("([A-Z])", " \\1", linked_data$Source_Code_File)
linked_data$Source_Code_File<-gsub("(?<=\\b\\w)\\s(?=\\w\\b)", "",linked_data$Source_Code_File,perl=T)
linked_data$Source_Code_File<-tolower(linked_data$Source_Code_File)
linked_data$Source_Code_File <- gsub('\\s+', ' ', linked_data$Source_Code_File)



count_of_required_non_linked_records <- 10 * nrow(linked_data)#for production this number will be approximately 910K 

distinct_file_names<-unique(dfWIRandom)
distinct_test_cases<-data.frame(unique(dfTCRandom[,c(1,2)]))

count_of_distinct_test_cases <- nrow(distinct_test_cases)
count_of_distinct_file_names <- length(distinct_file_names)

# Generate a bunch of pairs of test cases and file names, some will be conflicting, some will be linked, so let's add an extra 80%
number_of_samples <- as.integer(count_of_required_non_linked_records * 1.8)

random_links <- data.frame(
  test_case_index  = sample.int(count_of_distinct_test_cases, size = number_of_samples, replace = T), 
  file_name_index  = sample.int(count_of_distinct_file_names, size = number_of_samples, replace = T)
)
#get rid of duplicate pairs
random_links <- unique(random_links)

#let's create a hash table that cobtains filename and test case id as key and "0" as dummy value
#install.packages('hash')
library(hash)

linked_data_tbl <- hash( keys = paste(linked_data$source_code_file, linked_data$Test_Case_Id,sep="#"), values = 0)
random_file_name_tc_id_str <- paste(distinct_file_names[random_links$file_name_index] , distinct_test_cases$Test_Case_Id[random_links$test_case_index],sep="#")

#keep only those random_file_name_tc_id_str records that are not present in linked_data_tbl
non_linked_records <- random_file_name_tc_id_str[! has.key(random_file_name_tc_id_str, linked_data_tbl)]

#now let's split file name - test case id pairs into two separate variables in the data frame, so that you can easily access test case text

lst <- strsplit(non_linked_records, "#") 

unlinked_data <- as.data.frame( matrix(unlist(lst, use.names = FALSE), ncol = 2, byrow = T) )
colnames(unlinked_data) <- c("Source_Code_File", "Test_Case_Id")

unlinked_data[1:count_of_required_non_linked_records,]
colnames(distinct_test_cases)<-c("Test_Case_Id","Text")

dfNotLinked<-merge(unlinked_data,distinct_test_cases,on="Test_Case_Id",all.x=TRUE)

linked_data["relatedness_score"]<-2
dfNotLinked["relatedness_score"]<-1

#10*91315=456575
dfNotLinked<-dfNotLinked[1:913150,]
## This is the final trace matrix which will be used for train, test, dev
dfFinalTrace<-rbind(linked_data,dfNotLinked)

saveRDS(dfFinalTrace,file="/home/spoliset/dfFinalTrace.rds")


