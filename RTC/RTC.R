#### Scrips
### RTC.R for data retrieval from database
### RTC_Data_Selection.R for cleaning, split
### Andriys.R for building the trace matrix.

install.packages('tm')
install.packages('SnowballC')
install.packages('topicmodels')
install.packages('stringr')
install.packages("RMySQL")
install.packages("tidyr")
install.packages("splitstackshape")
install.packages("data.tree")
install.packages("networkD3")
install.packages("wordcloud")
install.packages("qdap")
install.packages("proxy")
install.packages("lsa")
install.packages("text2vec")
install.packages("quanteda")
install.packages("jsonlite")
library(networkD3)
library(tm)
library(SnowballC)
library(topicmodels)
library(RMySQL)
library(tidyr)
library(splitstackshape)
library(data.tree)
library(igraph)
library(ggplot2)
library(topicmodels)
library(parallel)
library(wordcloud)
library(proxy)
library(slam)
library(Matrix)
library(text2vec)
library(quanteda)
library(jsonlite)


######### Fetching the extracted RTC data from MySQL #############
rtcDB = dbConnect(MySQL(), user='root', password='####', dbname='RTC', host='localhost')
dbListTables(rtcDB)

## Fetch the list of work items which HAVE change sets and .xxx files in the changes.
rs = dbSendQuery(rtcDB, "select * from WorkItems  where file <> 'Work item has no change sets'")
workItems = fetch(rs, n=-1)
dfWorkItems<-as.data.frame(workItems)

## Fetch the list of New Story Test work items
rsNst<-dbSendQuery(rtcDB,"select * from NewStoryTest")
nst<-fetch(rsNst,n=-1)
dfNST<-as.data.frame(nst)

## Fetch the list of Comments made on the New Story Test Work Items
rsNstComm<-dbSendQuery(rtcDB,"select workItem, Combined_Text from NSTComments_Combined")
nstComm<-fetch(rsNstComm,n=-1)
dfNSTComm<-as.data.frame(nstComm)

## Fetch the list of RQM Test Case Items
rsRQMTC<-dbSendQuery(rtcDB,"select * from RQMTestCase")
rqmTC<-fetch(rsRQMTC,n=-1)
dfrqmTC<-as.data.frame(rqmTC)


## Fetch the RQM Test Cases-RTC Story Mapping
rsRQMTCStoryMap<-dbSendQuery(rtcDB,"select * from RQMTestCase_StoryMapping")
RQMTCStoryMap<-fetch(rsRQMTCStoryMap,n=-1)
dfRQMTCStoryMap<-as.data.frame(RQMTCStoryMap)


## Fetch the RQM Test Cases-Defect Mapping
rsRQMTCDefectMap<-dbSendQuery(rtcDB,"select * from RQMTestCaseDefectMap")
RQMTCDefectMap<-fetch(rsRQMTCDefectMap,n=-1)
dfRQMTCDefectMap<-as.data.frame(RQMTCDefectMap)

## Fetch the list of test scripts from RQM
rsRQMTS<-dbSendQuery(rtcDB,"select * from RQMTestScript")
RQMTS<-fetch(rsRQMTS,n=-1)
dfRQMTS<-as.data.frame(RQMTS)

## Fetch the RQM Test Case-Test Script Mapping
rsRQMTCTSMap<-dbSendQuery(rtcDB,"select * from RQMTestCase_TestScriptMapping")
RQMTCTSMap<-fetch(rsRQMTCTSMap,n=-1)
dfRQMTCTSMap<-as.data.frame(RQMTCTSMap)

### Joining All the above tables to get the Test Case Attributes Mapping To Source Code Files ####

## Join NST Comments with the NST parent table and the work items table based on the NST parent=work item id
rsNST1<-dbSendQuery(rtcDB,"SELECT a.id AS Test_Case_Id, a.plannedFor AS NST_planned_Release,
                          a. summary AS Test_Case_Summary, a.description AS Test_Case_Description, 
                          b.id AS WI_Id,b.plannedFor AS WI_planned_Release,b.workitemType AS Type,b.file AS Source_Code_File,c.Combined_Text AS Test_Case_Comment
                          FROM NewStoryTest  AS a
                          INNER JOIN WorkItems AS b
                          ON a.parent=b.id
                          LEFT OUTER JOIN NSTComments_Combined AS c
                          ON a.Id=c.workItem
                          WHERE b.file <> 'Work item has no change sets'")


TempNST1<-fetch(rsNST1,n=-1)
dfNST1<-as.data.frame(TempNST1)


## Join NST Comments with the NST parent table and the work items table based on the NST parent= work item parent
rsNST2<-dbSendQuery(rtcDB,"SELECT a.id AS Test_Case_Id, a.plannedFor AS NST_planned_Release,
                          a. summary AS Test_Case_Summary, a.description AS Test_Case_Description, 
                          b.id AS WI_Id,b.plannedFor AS WI_planned_Release,b.workitemType AS Type,b.file AS Source_Code_File,c.Combined_Text AS Test_Case_Comment
                          FROM NewStoryTest  AS a
                          INNER JOIN WorkItems AS b
                          ON a.parent=b.parent
                          LEFT OUTER JOIN NSTComments_Combined AS c
                          ON a.Id=c.workItem
                          WHERE b.file <> 'Work item has no change sets'")

TempNST2<-fetch(rsNST2,n=-1)
dfNST2<-as.data.frame(TempNST2)


dfNSTFinal<-rbind(dfNST1,dfNST2)
## Join RQMTestCase with Work Items, RQMTestScript, RQMTestCaseTestScriptMapping, RQMTestCaseStoryMapping and RQMTestCaseDefectMapping tables

## RQM Test Case-->Work Item(Story)-->file
rsRQM1<-dbSendQuery(rtcDB,"SELECT a.testcaseid AS Test_Case_Id, c.plannedFor As TC_planned_Release,b.id AS WI_Id,b.plannedFor AS WI_planned_Release,
                            b.file AS Source_Code_File,b.workitemType AS Type,c.title As Test_Case_Title, c.description AS Test_Case_description, 
                            c.design AS Test_Case_Design,c.testCaseprocedure AS Test_Case_Procedure,c.expectedResult AS Test_Case_Expected_Result,
                            e.title AS Test_Script_Title, e.description AS Test_Script_Description,e.steps AS Test_Script_Steps
                            FROM RQMTestCase_StoryMapping AS a
                            INNER JOIN WorkItems AS b 
                            ON a.storyId=b.id
                            INNER JOIN RQMTestCase AS c 
                            ON a.testcaseId= c.id
                            LEFT OUTER JOIN RQMTestCase_TestScriptMapping As d
                            ON a.testcaseId=d.TestCaseID
                            LEFT OUTER JOIN RQMTestScript e
                            ON d.TestScriptID=e.id
                            WHERE b.file <> 'Work item has no change sets'")
TempRQM1<-fetch(rsRQM1,n=-1)

dfRQM1<-as.data.frame(TempRQM1)


## RQM Test Case-->Work Item(Story)-->children

rsRQM2<-dbSendQuery(rtcDB,"SELECT a.testcaseid AS Test_Case_Id, c.plannedFor As TC_planned_Release,b.id AS WI_Id,b.plannedFor AS WI_planned_Release,
                            b.file AS Source_Code_File,b.workitemType AS Type,c.title As Test_Case_Title, c.description AS Test_Case_description,
                            c.design AS Test_Case_Design,c.testCaseprocedure AS Test_Case_Procedure,c.expectedResult AS Test_Case_Expected_Result,
                            e.title AS Test_Script_Title, e.description AS Test_Script_Description,e.steps AS Test_Script_Steps
                            FROM RQMTestCase_StoryMapping AS a
                            INNER JOIN WorkItems AS b 
                            ON a.storyId=b.parent
                            INNER JOIN RQMTestCase AS c 
                            ON a.testcaseId= c.id
                            LEFT OUTER JOIN RQMTestCase_TestScriptMapping As d
                            ON a.testcaseId=d.TestCaseID
                            LEFT OUTER JOIN RQMTestScript e
                            ON d.TestScriptID=e.id
                            WHERE b.file <> 'Work item has no change sets'")
TempRQM2<-fetch(rsRQM2,n=-1)
dfRQM2<-as.data.frame(TempRQM2)


## RQM Test Case-->Work Item(Defect)-->file
rsRQM3<-dbSendQuery(rtcDB,"SELECT a.ID AS Test_Case_Id,c.plannedFor As TC_planned_Release,b.id AS WI_Id,b.plannedFor AS WI_planned_Release,
                            b.file AS Source_Code_File,b.workitemType AS Type,c.title As Test_Case_Title, c.description AS Test_Case_description,
                            c.design AS Test_Case_Design,c.testCaseprocedure AS Test_Case_Procedure,c.expectedResult AS Test_Case_Expected_Result,
                            e.title AS Test_Script_Title, e.description AS Test_Script_Description,e.steps AS Test_Script_Steps
                            FROM RQMTestCaseDefectMap AS a
                            INNER JOIN WorkItems AS b 
                            ON a.Defect=b.id
                            INNER JOIN RQMTestCase AS c 
                            ON a.ID= c.id
                            LEFT OUTER JOIN RQMTestCase_TestScriptMapping As d
                            ON a.ID=d.TestCaseID
                            LEFT OUTER JOIN RQMTestScript e
                            ON d.TestScriptID=e.id
                            WHERE b.file <> 'Work item has no change sets'")
TempRQM3<-fetch(rsRQM3,n=-1)
dfRQM3<-as.data.frame(TempRQM3)


## RQM Test Case--> Work Item(Defect)-->parent

rsRQM4<-dbSendQuery(rtcDB,"SELECT a.ID AS Test_Case_Id,c.plannedFor As TC_planned_Release,b.id AS WI_Id,b.plannedFor AS WI_planned_Release,
                            b.file AS Source_Code_File,b.workitemType AS Type,c.title As Test_Case_Title, c.description AS Test_Case_description,
                            c.design AS Test_Case_Design,c.testCaseprocedure AS Test_Case_Procedure,c.expectedResult AS Test_Case_Expected_Result,
                            e.title AS Test_Script_Title, e.description AS Test_Script_Description,e.steps AS Test_Script_Steps
                            FROM RQMTestCaseDefectMap AS a
                            INNER JOIN WorkItems AS b 
                            ON a.Defect=b.parent
                            INNER JOIN RQMTestCase AS c 
                            ON a.ID= c.id
                            LEFT OUTER JOIN RQMTestCase_TestScriptMapping As d
                            ON a.ID=d.TestCaseID
                            LEFT OUTER JOIN RQMTestScript e
                            ON d.TestScriptID=e.id
                            WHERE b.file <> 'Work item has no change sets'")
TempRQM4<-fetch(rsRQM4,n=-1)
dfRQM4<-as.data.frame(TempRQM4)


dbDisconnect(rtcDB)

dfRQMFinal<-rbind(dfRQM1,dfRQM2,dfRQM3,dfRQM4)

saveRDS(dfRQMFinal,"/Users/sravyapolisetty/Desktop/RQMFinal.rds")
saveRDS(dfNSTFinal,"/Users/sravyapolisetty/Desktop/NSTFinal.rds")

######################## Start Here For Testing ########################################
dfRQMFinal<-readRDS("/Users/sravyapolisetty/Desktop/RQMFinal.rds")
dfNSTFinal<-readRDS("/Users/sravyapolisetty/Desktop/NSTFinal.rds")


df1<-dfNSTFinal[,c(1,2,5,6,8)]
df2<-dfRQMFinal[,c(1,2,3,4,5)]
df3<-dfNSTFinal[,c(1,3,4,8,9)]
df4<-dfRQMFinal[,c(1,5,7,8,9,10,11,12,13,14)]

df3[is.na(df3)] <- " "
df4[is.na(df4)] <- " "

df3<-df3[grep('\\.',df3$Source_Code_File),]

names(df1)<-c('TC_Id','TC_Release','WI_Id','WI_Release','SC_File')
names(df2)<-c('TC_Id','TC_Release','WI_Id','WI_Release','SC_File')

df<-rbind(df1,df2)

saveRDS(df,file="/Users/sravyapolisetty/Desktop/Final_Mapping.rds")
write.csv(df,"/Users/sravyapolisetty/Desktop/RTC_Mapping.csv")

df3$Text<-paste(df3$Test_Case_Summary,df3$Test_Case_Description,df3$Test_Case_Comment,sep=".")
df3<-df3[,c(1,4,6)]

df4$Text<-paste(df4$Test_Case_Title,df4$Test_Case_description,df4$Test_Case_Design,
                df4$Test_Case_Procedure,df4$Test_Case_Expected_Result,df4$Test_Script_Title,
                df4$Test_Script_Description,df4$Test_Script_Steps,sep=".")

rogue.file<-grep('com.ibm.team.repository.common.transport.TeamServiceException',df4$Source_Code_File)

df4<-df4[-(rogue.file),c(1,2,11)]


df5<-rbind(df3,df4)
## This ends the data fetching part.
############################################### Saving Some Stuff ##################################################################
jsonFormat<-toJSON(df5)

write(jsonFormat,file="/Users/sravyapolisetty/Desktop/Output.json")


df["TC_Release_Count"]<-0
df["WI_Release_Count"]<-0

df<-aggregate(TC_Release_Count~TC_Id+TC_Release, df,function(x) length(unique(x)))
df<-aggregate(TC_Release_Count~TC_Release, df,FUN=NROW)
write.csv(df,"/Users/sravyapolisetty/Desktop/ReleaseStats.csv")

write.csv(dfRQMFinal,"/Users/sravyapolisetty/Desktop/dfRQMFinal.csv")
write.csv(dfNSTFinal,"/Users/sravyapolisetty/Desktop/dfNSTFinal.csv")








###################################### Exploratory Analysis ###################################################################################
## Number of unique test cases which are mapped to work items or their children and which inturn have change sets with .java
## and full path
unique(dfRQMFinal$Test_Case_Id)
unique(dfNSTFinal$Test_Case_Id)
######################## Data Analysis ############################
### File Name Tree Structure ####
dfNSTFileNames<-unique(as.data.frame(dfNSTFinal[,c(1,8)]))
dfRQMFileNames<-unique(as.data.frame(dfRQMFinal[,c(1,5)]))

colnames(dfNSTFileNames)<-c('Test_Case','name')
colnames(dfRQMFileNames)<-c('Test_Case','name')
dfScFileName<-rbind(dfNSTFileNames,dfRQMFileNames)

dfFileNames<-rbind(dfNSTFileNames,dfRQMFileNames)

dfFileNames$pathString <- paste("filehierarchy", 
                            dfFileNames$name, 
                            sep = "/")

FileTree<-as.Node(dfFileNames[1:35,])
print(FileTree)

plot(as.dendrogram(FileTree))

useRtreeList <- ToListExplicit(FileTree, unname = TRUE)
radialNetwork( useRtreeList)

####  New Story Test Case mapped to number of Work Item Types
temp<-dfNSTFinal[,c(1,7)]
temp["Count"]<-0

df_agg <- aggregate(Count~Test_Case_Id+Type,temp,FUN=NROW)
df_agg<-aggregate(Count~Type,df_agg,FUN=NROW)

print(df_agg)

### RQM Test Case mapped to number of Work Item Types
temp<-temp[,0]
temp<-dfRQMFinal[,c(1,6)]
temp["Type_Count"]<-0
df_agg <- aggregate(Type_Count~Test_Case_Id+Type,temp,FUN=NROW)
df_agg<-aggregate(Type_Count~Type,df_agg,FUN=NROW)

print(df_agg)

#### Distribution of Number of distinct Files For each Work Item Type mapped to New Story Test ####
temp<-temp[,0]
temp<-dfNSTFinal[,c(1,7,8)]
temp["Count"]<-0

df_agg <- aggregate(Count~Test_Case_Id+Type+Source_Code_File,temp,FUN=NROW)
df_agg<-aggregate(Count~Test_Case_Id+Type,df_agg,FUN=NROW)
summary(df_agg$Count)

ggplot() + geom_line(data=df_agg, aes(x=Test_Case_Id, y=Count,color=Type))+ylim(0, 200)

ggplot(df_agg, aes(x=Test_Case_Id, y=Count,color=Type))+geom_point()+ylim(0, 200)

#### Distribution of Number of distinct Files For each Work Item Type mapped to RQM Test Case
temp<-temp[,0]
temp<-dfRQMFinal[,c(1,5,6)]
temp["Count"]<-0
df_agg <- aggregate(Count~Test_Case_Id+Type+Source_Code_File,temp,FUN=NROW)
df_agg<-aggregate(Count~Test_Case_Id+Type,df_agg,FUN=NROW)
summary(df_agg$Count)
############################################################
dfNST.SC<-as.data.frame(unique(dfNSTFinal[,8]))
dfRQM.SC<-as.data.frame(unique(dfRQMFinal[,5]))

#### NST Count: 230
#### RQM Count: 2763

df1<-dfNSTFinal[,c(1,8)]
dfRQMFinal <- dfRQMFinal[!(is.na(dfRQMFinal$Test_Case_Title)) | !(is.na(dfRQMFinal$Test_Case_description)) |
                         !(is.na(dfRQMFinal$Test_Case_Design)) | !(is.na(dfRQMFinal$Test_Case_Procedure)) |  
                        !(is.na(dfRQMText$Test_Case_Expected_Result)) | !(is.na(dfRQMText$Test_Script_Title)) |
                        !(is.na(dfRQMFinal$Test_Script_Description)) | !(is.na(dfRQMFinal$Test_Script_Steps)),]

df2<-rbind(df1,dfRQMFinal[,c(1,5)])
df.mapping<-unique(df2)
write.csv(df.mapping,"/Users/sravyapolisetty/Desktop/mapping.csv")
################################## Data Preprocessing ########################
## Combining text fields
dfNSTText<-unique(dfNSTFinal[,c(1,3,4,8,9)])
dfNSTText["Entire_Text"]<-0

dfNSTText$Entire_Text<-paste(dfNSTText$Test_Case_Summary,dfNSTText$Test_Case_Description,dfNSTText$Test_Case_Comment)

#Check
dfNSTText[1,6]

dfRQMText<-unique(dfRQMFinal[,c(1,5,7:14)])
dfRQMText["Entire_Text"]<-0
dfRQMText$Entire_Text<-paste(dfRQMText$Test_Case_Title,dfRQMText$Test_Case_description,dfRQMText$Test_Case_Design,
                             dfRQMText$Test_Case_Procedure,dfRQMText$Test_Case_Expected_Result,dfRQMText$Test_Script_Title,
                             dfRQMText$Test_Script_Description,dfRQMText$Test_Script_Steps)

#dfRQMText$Entire_Text<-gsub("NA","",dfRQMText$Entire_Text)                          
#Check
dfRQMText[1,11]


###### Length Of Test Case #####
temp<-dfRQMText[,c(1,11)]
temp["TextLength"]<-0
df_textlen<-data.frame(Text=temp$Entire_Text,Length=apply(temp,2,nchar)[,2])
summary(df_textlen$Length)


## Cleaning text in test cases
dfCorpus<-dfNSTText[,c(1,6)]
dfCorpus<-rbind(dfCorpus,dfRQMText[,c(1,11)])
TestCaseCorpus<-Corpus(VectorSource(as.vector(dfCorpus$Entire_Text)))
dfCorpus[1,]
TestCaseCorpus


fix.contractions <- function(doc) {

  doc <- gsub("won't", "will not", doc)
  doc <- gsub("n't", " not", doc)
  doc <- gsub("'ll", " will", doc)
  doc <- gsub("'re", " are", doc)
  doc <- gsub("'ve", " have", doc)
  doc <- gsub("'m", " am", doc)
  # 's could be 'is' or could be possessive: it has no expansion
  doc <- gsub("'s", "", doc)
  return(doc)
}


TestCaseCorpus <- tm_map(TestCaseCorpus, content_transformer(gsub), 
                         pattern='&apos;', replacement="'")
TestCaseCorpus <- tm_map(TestCaseCorpus, content_transformer(gsub), 
                         pattern='&gt;', replacement="greater than")                      
TestCaseCorpus <- tm_map(TestCaseCorpus, content_transformer(gsub), 
                         pattern='&lt;', replacement="lesser than")      
TestCaseCorpus <- tm_map(TestCaseCorpus, content_transformer(gsub), 
                         pattern='&#13;|&#10;|&quot;|\nx|\n|\t',replacement=" ")

TestCaseCorpus <- tm_map(TestCaseCorpus, fix.contractions)


TestCaseCorpus<-tm_map(TestCaseCorpus,content_transformer(gsub),pattern="[^[:alnum:]]",
                       replacement=" ")

TestCaseCorpus <- tm_map(TestCaseCorpus, content_transformer(removePunctuation)) 

TestCaseCorpus <- tm_map(TestCaseCorpus, content_transformer(tolower)) 

TestCaseCorpus <- tm_map(TestCaseCorpus, content_transformer(removeNumbers)) 

TestCaseCorpus  <- tm_map(TestCaseCorpus , content_transformer(removeWords), stopwords("en"))

TestCaseCorpus  <- tm_map(TestCaseCorpus , content_transformer(stemDocument), language = "english")

strwrap(TestCaseCorpus[1])


aggregate.plurals <- function (v) {
  aggr_fn <- function(v, singular, plural) {
    if (! is.na(v[plural])) {
      v[singular] <- v[singular] + v[plural]
      v <- v[-which(names(v) == plural)]
    }
    return(v)
  }
  for (n in names(v)) {
    n_pl <- paste(n, 's', sep='')
    v <- aggr_fn(v, n, n_pl)
    n_pl <- paste(n, 'es', sep='')
    v <- aggr_fn(v, n, n_pl)
  }
  return(v)
}
############## Document Term Matrix #######################################
TC_DTM<-DocumentTermMatrix(TestCaseCorpus)
TestCaseCorpus
inspect(TC_DTM)
############ Building a Term Document Matrix ###########
TC_TDM <- TermDocumentMatrix(TestCaseCorpus,control = list(removePunctuation = TRUE, stopwords = TRUE))
inspect(TC_TDM)

m <- as.matrix(TC_TDM)
dim(m)
m[1:500, 1:2993]

v <- sort(rowSums(m),decreasing=TRUE)

# combine singular and plural forms of words
v <- aggregate.plurals(v)

d <- data.frame(word = names(v),freq=v)
head(d, 10)

barplot(d[1:20,]$freq, las = 2, names.arg = d[1:20,]$word,
        col ="lightblue", main ="Most frequent words",
        ylab = "Word frequencies")
################### Word Cloud ############################
set.seed(1234)
wordcloud(words = d[1:1000,1], freq = d[1:1000,2], min.freq = 1,
          max.words=200, random.order=FALSE, rot.per=0.35, 
          colors=brewer.pal(8, "Dark2"))
################## TF-IDF ###############
tc_dtm_tfidf <- DocumentTermMatrix(TestCaseCorpus, control = list(weighting = weightTfIdf))

inspect(tc_dtm_tfidf)

tc_dtm_tfidf = removeSparseTerms(tc_dtm_tfidf, 0.95)

inspect(tc_dtm_tfidf)

freq = data.frame(sort(colSums(as.matrix(tc_dtm_tfidf)), decreasing=TRUE))
wordcloud(rownames(freq), freq[,1], max.words=500, colors=brewer.pal(1, "Dark2"))

########### Visual relationship #####
df.TC <- as.data.frame(inspect(TC_TDM))
df.TC.scale <- scale(df.TC)
distance <- dist(df.TC.scale,method="euclidean")
fit <- hclust(distance, method="ward")
plot(fit)

########################################### Processing source code file names ##############################

SourceCodeFileNameCorpus<-Corpus(VectorSource(as.vector((dfScFileName$name))))

SourceCodeFileNameCorpus
strwrap(SourceCodeFileNameCorpus[1])

SourceCodeFileNameCorpus <- tm_map(SourceCodeFileNameCorpus, content_transformer(gsub), 
                         pattern='/|\\.',replacement=" ")

SourceCodeFileNameCorpus <- tm_map(SourceCodeFileNameCorpus, content_transformer(tolower)) 

SourceCodeFileNameCorpus <- tm_map(SourceCodeFileNameCorpus, content_transformer(stemDocument),language="english") 


strwrap(SourceCodeFileNameCorpus[2])

############## Document Term Matrix #######################################
SC_DTM<-DocumentTermMatrix(SourceCodeFileNameCorpus)
SourceCodeFileNameCorpus
inspect(SC_DTM)

m <- as.matrix(SC_DTM)
dim(m)

m[1:50,1:25]
############ Building a Term Document Matrix ###########
SC_TDM <- TermDocumentMatrix(SourceCodeFileNameCorpus,control = list(removePunctuation = TRUE, stopwords = TRUE))

m <- as.matrix(SC_TDM)
dim(m)


v <- sort(rowSums(m),decreasing=TRUE)

d <- data.frame(word = names(v),freq=v)
head(d, 10)

barplot(d[1:20,]$freq, las = 2, names.arg = d[1:20,]$word,
        col ="lightblue", main ="Most frequent words",
        ylab = "Word frequencies")
################### Word Cloud ############################
set.seed(1234)
wordcloud(words = d[1:1000,1], freq = d[1:1000,2], min.freq = 1,
          max.words=200, random.order=FALSE, rot.per=0.35, 
          colors=brewer.pal(8, "Dark2"))
################## TF-IDF ###############
sc_dtm_tfidf <- DocumentTermMatrix(SourceCodeFileNameCorpus, control = list(weighting = weightTfIdf))
inspect(sc_dtm_tfidf)
sc_dtm_tfidf = removeSparseTerms(sc_dtm_tfidf, 0.95)
sc_dtm_tfidf

inspect(sc_dtm_tfidf[1,1:20])

freq = data.frame(sort(colSums(as.matrix(sc_dtm_tfidf)), decreasing=TRUE))
wordcloud(rownames(freq), freq[,1], max.words=500, colors=brewer.pal(1, "Dark2"))

########### Visual relationship #####
df.SC <- as.data.frame(inspect(SC_TDM))
df.SC.scale <- scale(df.SC)
distance <- dist(df.SC.scale,method="euclidean")
fit <- hclust(distance, method="ward")
plot(fit)

df.SC <- as.data.frame(inspect(SC_TDM))
df.SC.scale <- scale(df.SC)
distance <- dist(df.SC.scale,method="cosine")
fit <- hclust(distance, method="ward")
plot(fit)



