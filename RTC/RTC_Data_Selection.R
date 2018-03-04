### Script 2
##For selecting Non-Linked TC-SC mappings and combine with linked to get the final trace matrix, which is
### is cleansed and later split into train, validation and test sets

### df5 has the Linked Test Case to Source Code File data
### dfWI has the list of all distinct source code files in RTC
### dfTestCases has the list of all the distinct test cases in RTC

library(plyr)
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
library(xml2)
library(stringr)
library(qdap)


# Linked Records
dfLinked<-df5[,c(2,3)]


## Getting Only New Story Test and RQM Test Cases from db
rtcDB = dbConnect(MySQL(), user='root', password='####', dbname='RTC', host='localhost')
dbListTables(rtcDB)

NewStoryTest<-dbSendQuery(rtcDB,"SELECT a.id AS Test_Case_Id,a.summary AS Summary, a.description AS Description,
                          b.Combined_Text AS Test_Case_Comment
                          FROM NewStoryTest a
                          LEFT OUTER JOIN NSTComments_Combined b
                          ON a.Id=b.workItem")

NstTemp<-fetch(NewStoryTest,n=-1)
dfNSTAttr<-as.data.frame(NstTemp)

dfNSTAttr$Text<-paste(dfNSTAttr$Summary,dfNSTAttr$Description,sep=".")

RQMTest<-dbSendQuery(rtcDB,"SELECT c.id AS Test_Case_Id,c.title As Test_Case_Title, c.description AS Test_Case_description,
                     c.design AS Test_Case_Design,c.testCaseprocedure AS Test_Case_Procedure,c.expectedResult AS Test_Case_Expected_Result,
                     e.title AS Test_Script_Title, e.description AS Test_Script_Description,e.steps AS Test_Script_Steps
                     FROM RQMTestCase AS c
                     LEFT OUTER JOIN RQMTestCase_TestScriptMapping As d
                     ON c.id=d.TestCaseID
                     LEFT OUTER JOIN RQMTestScript e
                     ON d.TestScriptID=e.id")
RQMTemp<-fetch(RQMTest,n=-1)
dfRQMAttr<-as.data.frame(RQMTemp)

dfRQMAttr$Text<-paste(dfRQMAttr$Test_Case_Title,dfRQMAttr$Test_Case_description,dfRQMAttr$Test_Case_Design,
                      dfRQMAttr$Test_Case_Procedure,dfRQMAttr$Test_Case_Expected_Result,dfRQMAttr$Test_Script_Title,
                      dfRQMAttr$Test_Script_Description,dfRQMAttr$Test_Script_Steps,sep=".")


dfTestCases<-rbind(dfNSTAttr[,c(1,5)],dfRQMAttr[,c(1,10)])



WIList<-dbSendQuery(rtcDB,"SELECT DISTINCT file FROM WorkItems WHERE file <> 'Work item has no change sets'")
WITemp<-fetch(WIList, n=-1)
dfWI<-as.data.frame(WITemp)

dfWI$file<-gsub("[^[:alnum:]]"," ",dfWI$file)
dfWI$file<-gsub("([A-Z])", " \\1", dfWI$file)
dfWI$file<-gsub("(?<=\\b\\w)\\s(?=\\w\\b)", "",dfWI$file,perl=T)
dfWI$file<-tolower(dfWI$file)
dfWI$file<- gsub('\\s+', ' ', dfWI$file)

dfWIRandom<-dfWI[sample(nrow(dfWI)),]
dfTCRandom<-as.data.frame(dfTestCases[sample(nrow(dfTestCases)),])

names(dfWIRandom)<-"file"
names(dfTCRandom)<-c("Test_Case_Id","Text")

saveRDS(dfLinked,file="~/Desktop/dfLinked.rds")
saveRDS(dfWIRandom, file="~/Desktop/dfWIRandom.rds")
saveRDS(dfTCRandom, file="~/Desktop/dfTCRandom.rds")

############ Run Andriys.R on server to generate links ###########
dfFinalTrace<-readRDS(file="~/Downloads/dfFinalTrace.rds")
nrow(dfFinalTrace[dfFinalTrace$relatedness_score==2,])
#############################################################################################################################

######################## Cleansing final trace matrix ####################
library(tm)
library(SnowballC)
TCCorpus<-Corpus(VectorSource(as.vector(dfFinalTrace$Text)))
TCCorpus

TCCorpus <- tm_map(TCCorpus, content_transformer(gsub), 
                         pattern='&apos;', replacement="'")
TCCorpus <- tm_map(TCCorpus, content_transformer(gsub), 
                         pattern='&gt;', replacement="greater than")                      
TCCorpus <- tm_map(TCCorpus, content_transformer(gsub), 
                         pattern='&lt;', replacement="lesser than")      
TCCorpus <- tm_map(TCCorpus, content_transformer(gsub), 
                         pattern='&#13;|&#10;|&#160;|&quot;|\nx|\n|\t|NA|na',replacement=" ")

TCCorpus<-tm_map(TCCorpus,content_transformer(gsub),pattern="[^[:alnum:]]",
                    replacement=" ")

TCCorpus <- tm_map(TCCorpus, content_transformer(tolower)) 

TCCorpus <- tm_map(TCCorpus, content_transformer(stripWhitespace))


dfFinalTrace["Cleaned_Text"] <- data.frame(text=sapply(TCCorpus, identity), stringsAsFactors=F)

dfFinalTrace["pair_ID"]<- seq.int(nrow(dfFinalTrace))
colnames(dfFinalTrace)
dfFinalTrace<-dfFinalTrace[,c(6,5,2,4)]
names(dfFinalTrace)<-c("pair_ID","sentence_A","sentence_B","relatedness_score")
dfFinalTrace["entailment_judgment"]<-" "


dfFinalTrace <- within(dfFinalTrace, entailment_judgment[relatedness_score == 1] <- 'CONTRADICTION')
dfFinalTrace <- within(dfFinalTrace, entailment_judgment[relatedness_score == 2] <- 'ENTAILMENT')

saveRDS(dfFinalTrace,file="/home/spoliset/dfFinalTrace.rds")

## Splitting into 45% train,45% test,10% validation sets

set.seed(1234)
ind <- sample(3, nrow(dfFinalTrace), replace=TRUE, prob=c(45/100,45/100,10/100))
training <- dfFinalTrace[ind==1, ]
test <-  dfFinalTrace[ind==2, ] 
dev <-  dfFinalTrace[ind==3, ]

df.src_artf<-as.data.frame(unique(dfFinalTrace[,2]))
df.trg_artf<-as.data.frame(unique(dfFinalTrace[,3]))

df.src_artf["Id"]<- seq.int(nrow(df.src_artf))
df.trg_artf["Id"]<- seq.int(nrow(df.trg_artf))


nrow(training[training$relatedness_score==1,])

write.table(training,file="/home/spoliset/train_symbol_0.txt",sep = "\t" ,row.names=FALSE,quote = FALSE)
write.table(test,file="/home/spoliset/test_symbol_0.txt",sep = "\t" ,row.names=FALSE,quote = FALSE)
write.table(dev,file="/home/spoliset/validation_symbol_0.txt",sep = "\t" ,row.names=FALSE,quote = FALSE)

write.table(df.src_artf[,1],file="/home/spoliset/src_sentence.txt",row.names=FALSE,quote = FALSE,col.names = FALSE)
write.table(df.trg_artf[,1],file="/home/spoliset/trg_sentence.txt",row.names=FALSE,quote = FALSE,col.names = FALSE)
write.table(df.src_artf[,2],file="/home/spoliset/src_id.txt",row.names=FALSE,quote = FALSE,col.names=FALSE)
write.table(df.trg_artf[,2],file="/home/spoliset/trg_id.txt",row.names=FALSE,quote = FALSE,col.names=FALSE)

#### Get all the corpus in text cases and source code files--these are for training the word embeddings

write.table(dfTestCases[,2],file="~/Desktop/IBM_Corpus.txt",quote=FALSE, sep=" ", col.names =FALSE, row.names = FALSE )
write.table(dfWI,file="~/Desktop/IBM_Corpus.txt",quote=FALSE, sep=" ", col.names =FALSE, append= TRUE, row.names = FALSE )
