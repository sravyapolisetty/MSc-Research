################## Contribution of bug attributes in predicting the bug CC list ######

##Exploratory Analysis on the New Data Set

##Setting SPARK environment, starting SPARK session and reading data from MongoDB via SPARK-MONGO connector

Sys.setenv(SPARK_HOME = "/usr/local/Cellar/apache-spark/2.1.0/libexec/")
.libPaths(c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib"), .libPaths()))

library(SparkR)
library(graphics)
library(plotrix)
library(corrplot)

#sparkR.stop()

sparkR.session(sparkPackages = "com.stratio.datasource:spark-mongodb_2.11:0.12.0")


spark.df.bug_cc_details<- read.df("",source ="com.mongodb.spark.sql.DefaultSource", 
                                  uri = "mongodb://127.0.0.1/Mozilla_CASCON.bug_cc_details")

spark.df.bug_creator_details<-read.df("",source ="com.mongodb.spark.sql.DefaultSource", 
                                      uri = "mongodb://127.0.0.1/Mozilla_CASCON.bug_creator_details")

spark.df.bug_depends_on<-read.df("",source ="com.mongodb.spark.sql.DefaultSource", 
                                 uri = "mongodb://127.0.0.1/Mozilla_CASCON.bug_depends_on")

spark.df.bug_flags<-read.df("",source ="com.mongodb.spark.sql.DefaultSource", 
                            uri = "mongodb://127.0.0.1/Mozilla_CASCON.bug_flags")

spark.df.bug_keywords<-read.df("",source ="com.mongodb.spark.sql.DefaultSource", 
                               uri = "mongodb://127.0.0.1/Mozilla_CASCON.bug_keywords")

spark.df.bug_mentor_details<-read.df("",source ="com.mongodb.spark.sql.DefaultSource", 
                                     uri = "mongodb://127.0.0.1/Mozilla_CASCON.bug_mentor_details")

spark.df.bug_qa_details<-read.df("",source ="com.mongodb.spark.sql.DefaultSource", 
                                 uri = "mongodb://127.0.0.1/Mozilla_CASCON.bug_qa_details")

spark.df.bug_assigned_to_details<-read.df("",source ="com.mongodb.spark.sql.DefaultSource", 
                                          uri = "mongodb://127.0.0.1/Mozilla_CASCON.bug_assigned_to_details")

spark.df.bug_blocks<-read.df("",source ="com.mongodb.spark.sql.DefaultSource", 
                             uri = "mongodb://127.0.0.1/Mozilla_CASCON.bug_blocks")

spark.df.bugs<-read.df("",source ="com.mongodb.spark.sql.DefaultSource", 
                       uri = "mongodb://127.0.0.1/Mozilla_CASCON.bugs")

spark.df.Commits<-read.df("",source ="com.mongodb.spark.sql.DefaultSource", 
                          uri = "mongodb://127.0.0.1/Mozilla_CASCON.commits")

spark.df.Commits_Bugs_Mapping<-read.df("",source ="com.mongodb.spark.sql.DefaultSource", 
                                       uri = "mongodb://127.0.0.1/Mozilla_CASCON.commits_bugs_mapping")

spark.df.Commits_Files_Mapping<-read.df("",source ="com.mongodb.spark.sql.DefaultSource", 
                                        uri = "mongodb://127.0.0.1/Mozilla_CASCON.commits_files_mapping")

spark.df.Patch_Flags<-read.df("",source ="com.mongodb.spark.sql.DefaultSource", 
                              uri = "mongodb://127.0.0.1/Mozilla_CASCON.Patch_Flags")

spark.df.patches<-read.df("",source ="com.mongodb.spark.sql.DefaultSource", 
                          uri = "mongodb://127.0.0.1/Mozilla_CASCON.patches")


createOrReplaceTempView(spark.df.bug_cc_details, "bug_cc_details")
createOrReplaceTempView(spark.df.bug_creator_details,"bug_creator_details")
createOrReplaceTempView(spark.df.bug_depends_on,"bug_depends_on")
createOrReplaceTempView(spark.df.bug_flags,"bug_flags")
createOrReplaceTempView(spark.df.bug_keywords,"bug_keywords")
createOrReplaceTempView(spark.df.bug_mentor_details,"bug_mentor_details")
createOrReplaceTempView(spark.df.bug_qa_details,"bug_qa_details")
createOrReplaceTempView(spark.df.bug_assigned_to_details,"bug_assigned_to_details")
createOrReplaceTempView(spark.df.bug_blocks,"bug_blocks")
createOrReplaceTempView(spark.df.bugs,"bugs")
createOrReplaceTempView(spark.df.Commits,"Commits")
createOrReplaceTempView(spark.df.Commits_Bugs_Mapping,"Commits_Bugs_Mapping")
createOrReplaceTempView(spark.df.Commits_Files_Mapping,"Commits_Files_Mapping")
createOrReplaceTempView(spark.df.Patch_Flags,"Patch_Flags")
createOrReplaceTempView(spark.df.patches,"patches")

## Number of bugs reports in each product

df.bug.product<-sql("SELECT COUNT(*) AS Number_Of_Bugs, product FROM bugs GROUP BY product")

R.dfbp<-as.data.frame(df.bug.product)

print(R.dfbp)

### Finding the Number of bugs a bug is dependent on
df.temp1<-sql("SELECT bg_id, COUNT(*) AS Depend_Count FROM bug_depends_on GROUP BY bg_id")
R.dftemp1<-as.data.frame(df.temp1)

### Finding the Number of bugs a bug blocks
df.temp2<-sql("SELECT bg_id, COUNT(*) AS Block_Count FROM bug_blocks GROUP BY bg_id")
R.dftemp2<-as.data.frame(df.temp2)

## Finding the length of CC List

df.temp3<-sql("SELECT bg_id, COUNT(*) AS CC_Count FROM bug_cc_details GROUP BY bg_id")
R.dftemp3<-as.data.frame(df.temp3)
R.dftemp3[R.dftemp3$bg_id==1300355,]

### Data Set with independent and dependent variables

#severity,priority,bug fix time, comment count,number of bugs it depends on, number of bugs it blocks--independent variables
## cc list count--dependent variable

df.temp<-sql("SELECT a.bg_id,a.votes,DATEDIFF(from_unixtime(unix_timestamp(c.date,'yyyy-mm-dd'),'yyyy-mm-dd'),from_unixtime(unix_timestamp(a.creation_time, 'yyyy-mm-dd'), 'yyyy-mm-dd')) AS Commit_Time,a.comment_count,a.product
             FROM bugs a INNER JOIN Commits_Bugs_Mapping b
             ON a.bg_id=b.bg_id
             INNER JOIN Commits c
             ON b.cs_index=c.cs_index")
            
R.dftemp<-as.data.frame(df.temp)

length(unique(R.dftemp[R.dftemp$Commit_Time<0,1]))

df.merge1<-merge.data.frame(R.dftemp, R.dftemp1,all.x = TRUE)
df.merge2<-merge(df.merge1,R.dftemp2,all.x=TRUE)
df.Final<-merge(df.merge2,R.dftemp3,all.x=TRUE)

df.Final[is.na(df.Final)] <- 0

df.Final$votes<-as.numeric(df.Final$votes)


sort(unique(df.Final$product))

df<-df.Final[df.Final$product=='mailnews core',]
cor(df$CC_Count,df$comment_count, method = c("pearson"))


####degrees of blockiness

nrow(df.Final)# Total bugs
nrow(df.Final[df.Final$Block_Count>=7,])


## Percentage of blockiness
#1
nrow(df.Final[df.Final$product=="firefox for android" & df.Final$Block_Count==0,])/nrow(df.Final[df.Final$product=="firefox for android",])*100


### Correlation plot
corrMatrix <- cor(df.Final[df.Final$product=='firefox',c(2,3,4,6,7,8)])
corrplot(corrMatrix, method="number",type="lower",upper.panel=panel.pts)


##### Commit Time For Blocking 
df.Final_Prod<-df.Final[df.Final$product=='firefox' | df.Final$product=='firefox os' | df.Final$product=='core'
                        | df.Final$product=='firefox for android' | df.Final$product=='toolkit' | df.Final$product=='seamonkey',
                        c(3,5,7)]

df.Final_Prod$Commit_Time <- ifelse(df.Final_Prod$Commit_Time==0, 0.1, df.Final_Prod$Commit_Time)


boxplot(Commit_Time ~ product, data=df.Final_Prod[df.Final_Prod$Block_Count==0,c(1,2)],
        main="Different boxplots showing Commit Time For blocking Bugs",
        xlab="Product",
        ylab="Commit Time in days (log scale)",
        col="orange",
        border="brown",
        log='y',las=0,names=c("core","FF","FF android","FF os","SM","TK"))



##### Commit Time For Non-Blocking 

boxplot(Resolution_Time ~ product, data=df.Final_Prod[df.Final_Prod$Block_Count!=0,c(1,2)],
        main="Different boxplots showing Commit Time For Non-blocking Bugs",
        xlab="Product",
        ylab="Commit Time in days (log scale)",
        col="orange",
        border="brown",
        log='y',names=c("core","FF","FF android","FF os","SM","TK"))



#### CC List Size Vs Blocking Bugs

df.Final_CC<-df.Final[df.Final$product=='firefox' | df.Final$product=='firefox os' | df.Final$product=='core'
                        | df.Final$product=='firefox for android' | df.Final$product=='toolkit' | df.Final$product=='seamonkey',
                        c(5,7,8)]

df.Final_CC$CC_Count <- ifelse(df.Final_CC$CC_Count==0, NA, df.Final_CC$CC_Count)


boxplot(CC_Count ~ product, data=df.Final_CC[df.Final_CC$Block_Count!=0,c(1,3)],
        main="Boxplots showing CC List Size For Blocking Bugs",
        xlab="Product",
        ylab="CC List Size(log scale)",
        col="orange",
        border="brown",
        log="y",
        names=c("core","FF","FF android","FF os","SM","TK"))

#### CC List Size Vs Non-Blocking Bugs
df.Final_CC<-df.Final[df.Final$product=='firefox' | df.Final$product=='firefox os' | df.Final$product=='core'
                      | df.Final$product=='firefox for android' | df.Final$product=='toolkit' | df.Final$product=='seamonkey',
                      c(5,7,8)]

df.Final_CC$CC_Count <- ifelse(df.Final_CC$CC_Count==0, NA, df.Final_CC$CC_Count)


boxplot(CC_Count ~ product, data=df.Final_CC[df.Final_CC$Block_Count==0,c(1,3)],
        main="Boxplots showing CC List Size For Non-Blocking Bugs",
        xlab="Product",
        ylab="CC List Size(log scale)",
        col="orange",
        border="brown",
        log="y",
        names=c("core","FF","FF android","FF os","SM","TK"))


##### Dependency Vs Blocking Bugs

df.Final_dep<-df.Final[df.Final$product=='firefox' | df.Final$product=='firefox os' | df.Final$product=='core'
                                    | df.Final$product=='firefox for android' | df.Final$product=='toolkit' | df.Final$product=='seamonkey',
                                    c(5,6,7)]

df.Final_dep$Depend_Count <- ifelse(df.Final_dep$Depend_Count==0, NA, df.Final_dep$Depend_Count)


boxplot(Depend_Count ~ product, data=df.Final_dep[df.Final_CC$Block_Count!=0,c(1,2)],
        main="Boxplots showing Dependent List Size For Blocking Bugs",
        xlab="Product",
        ylab="Dependent List Size (log scale)",
        col="orange",
        border="brown",
        log="y",
        names=c("core","FF","FF android","FF os","SM","TK"))

#### Dependency Vs Non-Blocking Bugs

boxplot(Depend_Count ~ product, data=df.Final_dep[df.Final_CC$Block_Count==0,c(1,2)],
        main="Boxplots showing Dependent List Size For Non=Blocking Bugs",
        xlab="Product",
        ylab="Dependent List Size (log scale)",
        col="orange",
        border="brown",
        log="y",
        names=c("core","FF","FF android","FF os","SM","TK"))


## Commit Time For Dependent Bugs

df.Final.Commit.dep<-df.Final[df.Final$product=='firefox' | df.Final$product=='firefox os' | df.Final$product=='core'
                              | df.Final$product=='firefox for android' | df.Final$product=='toolkit' | df.Final$product=='seamonkey',
                              c(3,5,6)]

df.Final.Commit.dep$Resolution_Time <- ifelse(df.Final.Commit.dep$Resolution_Time==0, NA, df.Final.Commit.dep$Resolution_Time)

boxplot(Resolution_Time ~ product, data=df.Final.Commit.dep[df.Final.Commit.dep$Depend_Count==0,c(1,2)],
        main="Boxplots showing Commit Time List Size For Independent Bugs",
        xlab="Product",
        ylab="Commit Time (log scale)",
        col="orange",
        border="brown",
        log="y",
        names=c("core","FF","FF android","FF os","SM","TK"))


boxplot(Resolution_Time ~ product, data=df.Final.Commit.dep[df.Final.Commit.dep$Depend_Count!=0,c(1,2)],
        main="Boxplots showing Commit Time List Size For Dependent Bugs",
        xlab="Product",
        ylab="Commit Time (log scale)",
        col="orange",
        border="brown",
        log="y",
        names=c("core","FF","FF android","FF os","SM","TK"))




###  Patch Size Vs Product
df.patch.prod<-sql("SELECT a.patchSize,b.product
FROM patches a INNER JOIN bugs b 
ON a.bg_id=b.bg_id")

R.dfpatch.prod<-as.data.frame(df.patch.prod)



dfPatch<-R.dfpatch.prod[R.dfpatch.prod$product=='firefox' | R.dfpatch.prod$product=='firefox os' | R.dfpatch.prod$product=='core'
                              | R.dfpatch.prod$product=='firefox for android' | R.dfpatch.prod$product=='toolkit' | R.dfpatch.prod$product=='seamonkey',]


library(stringr)
dfPatch["Measurement"]<-' '
dfPatch["Type"]<-' '

dfPatch$patchSize <- gsub(",","",dfPatch$patchSize)
dfPatch$patchSize <- gsub(";","",dfPatch$patchSize)
dfPatch$patchSize<-gsub("\\s+"," ",dfPatch$patchSize)

dfPatch[,c(1,3,4)]<-str_split_fixed(dfPatch$patchSize,' ', 3)

unique(dfPatch$patchSize)

dfPatch$patchSize<-as.factor(dfPatch$patchSize)
dfPatch$patchSize<-as.numeric(as.character(dfPatch$patchSize))
  


dfPatch$patchSize<-as.factor(dfPatch$patchSize)
dfPatch$patchSize<-as.numeric(as.character(dfPatch$patchSize))
dfPatch$patchSize<-ifelse(transform.default("kb",dfPatch$Measurement),dfPatch$patchSize*1000,dfPatch$patchSize)

dfPatch[which(is.na(dfPatch$patchSize)),]


boxplot(patchSize ~ product, data=R.dfpatch.prod,
        main="Boxplots showing Commit Time List Size For Dependent Bugs",
        xlab="Product",
        ylab="Patch Size",
        col="orange",
        border="brown",
        names=c("core","FF","FF android","FF os","SM","TK"))




