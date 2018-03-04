
###Setting SPARK Environment####
Sys.setenv(SPARK_HOME = "/usr/local/Cellar/apache-spark/2.1.0/libexec/")
.libPaths(c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib"), .libPaths()))

##Loading Library
library(SparkR)
library(graphics)
library(plotrix)

## Starting Spark Session
sparkR.session(sparkPackages = "com.stratio.datasource:spark-mongodb_2.11:0.12.0")

## Reading data from MongoDB

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
                          uri = "mongodb://127.0.0.1/Mozilla_CASCON.Commits")

spark.df.Commits_Bugs_Mapping<-read.df("",source ="com.mongodb.spark.sql.DefaultSource", 
                                       uri = "mongodb://127.0.0.1/Mozilla_CASCON.Commits_Bugs_Mapping")

spark.df.Commits_Files_Mapping<-read.df("",source ="com.mongodb.spark.sql.DefaultSource", 
                                        uri = "mongodb://127.0.0.1/Mozilla_CASCON.Commits_Files_Mapping")

spark.df.Patch_Flags<-read.df("",source ="com.mongodb.spark.sql.DefaultSource", 
                              uri = "mongodb://127.0.0.1/Mozilla_CASCON.Patch_Flags")

spark.df.patches<-read.df("",source ="com.mongodb.spark.sql.DefaultSource", 
                          uri = "mongodb://127.0.0.1/Mozilla_CASCON.patches")



### Stats on Bug Data
createOrReplaceTempView(spark.df.bug_depends_on, "bug_cc_details")
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


##Pie chart showing number of bugs in each phase
df.status<-sql("SELECT status,COUNT(*) AS COUNT FROM bugs GROUP BY status")
showDF(select(df.status,"*"))
R.dfstatus<-as.data.frame(df.status)
status.lables<-unlist(R.dfstatus$status)
x<-R.dfstatus$COUNT
piepercent<- round(100*x/sum(x), 2)
pie(x, radius = 1, main = "Bug Status pie chart",col=rainbow(length(x)),cex=0.5)
legend("bottomright", status.lables, cex =0.7,
       fill = rainbow(length(x)))

## Resolution And Status
df.res<-sql("SELECT bugs.resolution,COUNT(*) AS COUNT FROM bugstable GROUP BY bugs.resolution")
R.dfres<-as.data.frame(df.res)
res.labels<-unlist(R.dfres$resolution)
x<-R.dfres$COUNT
piepercent<- round(100*x/sum(x), 2)
pie(x, main = "Bug Resolution pie chart",col=rainbow(length(x)),cex=0.5)
legend("topright", res.labels, cex = 0.8,fill = rainbow(length(x)))


#### Patch Evolution

df.bugzilla<-sql("SELECT _id,bugs.classification,bugs.status,bugs.cf_last_resolved,bugs.severity,
                 bugs.creation_time,bugs.last_change_time FROM bugstable")
R.dfBugzilla<-as.data.frame(df.bugzilla)

## Patches With Positive Reviews Over the years
createOrReplaceTempView(spark.df.PosRev,"PRPatches")
df.PRPatches<-sql("SELECT YEAR(creation_time) AS Year, COUNT(*) AS Number 
                  FROM PRPatches 
                  GROUP BY YEAR(creation_time)")
R.dfPRPatches<-as.data.frame(df.PRPatches)
R.dfPRPatches<-R.dfPRPatches[order(R.dfPRPatches$Year),]
x<-R.dfPRPatches$Number
year.labels<-R.dfPRPatches$Year
barplot(x,names.arg=year.labels,xlab="Year",ylab="Number of Patches",main = "Evolution Of Patches with Positive Reviews")

#####################################################################################
## Number of bugs reports quarterly
install.packages("zoo")
install.packages("ade4")
install.packages("ggplot2")
library(dplyr)
library(lubridate)
library(zoo)
library(ade4)
library(ggplot2)


df.bugstats<-sql("SELECT _id,bugs[0].creation_time,bugs[0].product,bugs[0].component FROM bugstable
                 WHERE YEAR(bugs[0].creation_time)>2013")
R.dfbugstats<-as.data.frame(df.bugstats)    
names(R.dfbugstats)<-c("bug_id","creation_time","product","component")
unique(R.dfbugstats$product)
R.dfbugstats$Quarter_Year <- as.yearqtr(as.Date(R.dfbugstats$creation_time), "%m/%d/%Y")
R.dfbugstats["BugCount"]<-0
df_agg <- aggregate(BugCount~product+Quarter_Year,R.dfbugstats,FUN=NROW)
ggplot() + geom_line(data=df_agg, aes(x=Quarter_Year, y=BugCount,color=product)) +
  scale_x_yearqtr(format="%YQ%q", n=20)




## Patches With negative reviews over the years
createOrReplaceTempView(spark.df.NegRev,"NRPatches")
df.NRPatches<-sql("SELECT YEAR(creation_time) AS Year, COUNT(*) AS Number 
                  FROM NRPatches 
                  GROUP BY YEAR(creation_time)")
R.dfNRPatches<-as.data.frame(df.NRPatches)
R.dfNRPatches<-R.dfNRPatches[order(R.dfNRPatches$Year),]
x<-R.dfNRPatches$Number
year.labels<-R.dfNRPatches$Year
barplot(x,names.arg=year.labels,col=c(0,1),xlab="Year",ylab="Number of Patches",main = "Evolution Of Patches with Negative Reviews")


## Patches with positive reviews vs severity of the bug
df.PRVsSev<-sql("SELECT b.bugs.severity AS Severity,COUNT(*) AS Number
                FROM PRPatches a LEFT JOIN bugstable b
                ON a.bug_id=b._id 
                GROUP BY b.bugs.severity")
R.dfPRVsSev<-as.data.frame(df.PRVsSev)
x<-R.dfPRVsSev$Number
sev.labels<-unlist(R.dfPRVsSev$Severity)
barplot(x,names.arg=sev.labels,xlab="Severity",ylab="Number of Patches",
        main = "Number of Patches with Positive Reviews Vs Severity Of the bug",cex.main=0.7,cex.names =0.5,cex.axis = 0.5)



## Patches with negative reviews vs severity of the bug
df.NRVsSev<-sql("SELECT b.bugs.severity AS Severity,COUNT(*) AS Number
                FROM NRPatches a LEFT JOIN bugstable b
                ON a.bug_id=b._id 
                GROUP BY b.bugs.severity")
R.dfNRVsSev<-as.data.frame(df.NRVsSev)
x<-R.dfNRVsSev$Number
sev.labels<-unlist(R.dfNRVsSev$Severity)
barplot(x,names.arg=sev.labels,xlab="Severity",ylab="Number of Patches",
        main = "Number of Patches with Neg Reviews Vs Severity Of the bug")

## Patch Size for Patches which got Positive Reviews
df.PRPatchSize<-sql("SELECT size FROM PRPatches")
R.dfPRPatchSize<-as.data.frame(df.PRPatchSize)
summary(R.dfPRPatchSize$size)
boxplot(R.dfPRPatchSize$size,main="Patch Size for Patches which got Positive Reviews",
        ylab="Patch Size(Number of Changed Lines)")


## Patch Size for Patches which got Negative Reviews
df.NRPatchSize<-sql("SELECT size FROM NRPatches")
R.dfNRPatchSize<-as.data.frame(df.NRPatchSize)
summary(R.dfNRPatchSize$size)
boxplot(R.dfNRPatchSize$size,main="Patch Size for Patches which got Negative Reviews",
        ylab="Patch Size(Number of Changed Lines)")
#################################################################################################
## Patch Review Time for Patches which got a positive review vs Severity of the bug
df.PRRevTime<-sql("SELECT DATEDIFF(a.last_change_time,a.creation_time) AS Review_Time,b.bugs.severity AS Severity 
                    FROM PRPatches a LEFT JOIN bugstable b
                    ON a.bug_id=b._id")

R.dfPRRevTime<-as.data.frame(df.PRRevTime)
R.dfPRRevTime$Severity<-unlist(R.dfPRRevTime$Severity)

## Critical bugs
R.dfPRRevTime.Critical<-R.dfPRRevTime[R.dfPRRevTime$Severity=="critical",]
barplot(R.dfPRRevTime.Critical$Review_Time,main="Patch Review Time for patches
        with positive reviews and belonging to critical bugs",ylab="Time(days)")
summary(R.dfPRRevTime.Critical$Review_Time)

## Major bugs
R.dfPRRevTime.Major<-R.dfPRRevTime[R.dfPRRevTime$Severity=="major",]
barplot(R.dfPRRevTime.Major$Review_Time,main="Patch Review Time for patches
        with positive reviews and belonging to major bugs",ylab="Time(days)")
summary(R.dfPRRevTime.Major$Review_Time)

## Enhancement bugs
R.dfPRRevTime.Enh<-R.dfPRRevTime[R.dfPRRevTime$Severity=="enhancement",]
barplot(R.dfPRRevTime.Enh$Review_Time,main="Patch Review Time for patches
        with positive reviews and belonging to enhancement bugs",ylab="Time(days)")
summary(R.dfPRRevTime.Enh$Review_Time)
## Normal bugs
R.dfPRRevTime.Normal<-R.dfPRRevTime[R.dfPRRevTime$Severity=="normal",]
barplot(R.dfPRRevTime.Normal$Review_Time,main="Patch Review Time for patches
        with positive reviews and belonging to normal bugs",ylab="Time(days)")
summary(R.dfPRRevTime.Normal$Review_Time)
## Minor Bugs
R.dfPRRevTime.Minor<-R.dfPRRevTime[R.dfPRRevTime$Severity=="minor",]
barplot(R.dfPRRevTime.Minor$Review_Time,main="Patch Review Time for patches
        with positive reviews and belonging to minor bugs",ylab="Time(days)")
summary(R.dfPRRevTime.Minor$Review_Time)
## Trivial Bugs
R.dfPRRevTime.Trivial<-R.dfPRRevTime[R.dfPRRevTime$Severity=="trivial",]
barplot(R.dfPRRevTime.Trivial$Review_Time,main="Patch Review Time for patches
        with positive reviews and belonging to trivial bugs",ylab="Time(days)")
summary(R.dfPRRevTime.Trivial$Review_Time)

#######################################################################################
## Patch Review Time for Patches which got a negative review vs Severity of the bug
df.NRRevTime<-sql("SELECT DATEDIFF(a.last_change_time,a.creation_time) AS Review_Time,b.bugs.severity AS Severity 
                    FROM NRPatches a LEFT JOIN bugstable b
                  ON a.bug_id=b._id")

R.dfNRRevTime<-as.data.frame(df.NRRevTime)
R.dfNRRevTime$Severity<-unlist(R.dfNRRevTime$Severity)

## Critical bugs
R.dfNRRevTime.Critical<-R.dfNRRevTime[R.dfNRRevTime$Severity=="critical",]
barplot(R.dfNRRevTime.Critical$Review_Time,main="Patch Review Time for patches
        with negative reviews and belonging to critical bugs",ylab="Time(days)")
summary(R.dfNRRevTime.Critical$Review_Time)

## Major bugs
R.dfNRRevTime.Major<-R.dfPRRevTime[R.dfNRRevTime$Severity=="major",]
barplot(R.dfNRRevTime.Major$Review_Time,main="Patch Review Time for patches
        with negative reviews and belonging to major bugs",ylab="Time(days)")
summary(R.dfNRRevTime.Major$Review_Time)

## Enhancement bugs
R.dfNRRevTime.Enh<-R.dfNRRevTime[R.dfNRRevTime$Severity=="enhancement",]
barplot(R.dfNRRevTime.Enh$Review_Time,main="Patch Review Time for patches
        with negative reviews and belonging to enhancement bugs",ylab="Time(days)")
summary(R.dfNRRevTime.Enh$Review_Time)

## Normal bugs
R.dfNRRevTime.Normal<-R.dfNRRevTime[R.dfNRRevTime$Severity=="normal",]
barplot(R.dfNRRevTime.Normal$Review_Time,main="Patch Review Time for patches
        with negative reviews and belonging to normal bugs",ylab="Time(days)")
summary(R.dfNRRevTime.Normal$Review_Time)

## Minor Bugs
R.dfNRRevTime.Minor<-R.dfNRRevTime[R.dfNRRevTime$Severity=="minor",]
barplot(R.dfNRRevTime.Minor$Review_Time,main="Patch Review Time for patches
        with negative reviews and belonging to minor bugs",ylab="Time(days)")
summary(R.dfNRRevTime.Minor$Review_Time)

## Trivial Bugs
R.dfNRRevTime.Trivial<-R.dfNRRevTime[R.dfNRRevTime$Severity=="trivial",]
barplot(R.dfNRRevTime.Trivial$Review_Time,main="Patch Review Time for patches
        with negative reviews and belonging to trivial bugs",ylab="Time(days)")
summary(R.dfNRRevTime.Trivial$Review_Time)

############################################################################
# Patch Review Time for all All patches which got a positive review

df.PRRevTime<-sql("SELECT DATEDIFF(last_change_time,creation_time) AS Review_Time  
                    FROM PRPatches")
R.df.PRRevTime<-as.data.frame(df.PRRevTime)
barplot(R.df.PRRevTime$Review_Time,main="Patch Review Time for patches
        with positive reviews",ylab="Time(days)")
summary(R.df.PRRevTime$Review_Time)


# Patch Review Time for all All patches which got a negative review
df.NRRevTime<-sql("SELECT DATEDIFF(last_change_time,creation_time) AS Review_Time  
                    FROM NRPatches")
R.df.NRRevTime<-as.data.frame(df.NRRevTime)
barplot(R.df.NRRevTime$Review_Time,main="Patch Review Time for patches
        with negative reviews",ylab="Time(days)")

summary(R.df.NRRevTime$Review_Time)

#################################################################################
# PosRev patches vs severity
df.sev<-sql("SELECT b.bugs.severity AS Severity, COUNT(*) AS Number  
            FROM PRPatches a LEFT JOIN bugstable b
            ON a.bug_id=b._id
            GROUP BY b.bugs.severity")
R.dfSev<-as.data.frame(df.sev)
sev.lables<-unlist(R.dfSev$Severity)
x<-R.dfSev$Number
piepercent<- round(100*x/sum(x), 2)
pie(x, labels = piepercent, main = "Severity of Patches with positive reviews",col=rainbow(length(x)))
legend("topright", sev.lables, cex = 0.8,
       fill = rainbow(length(x)))

# NegRev patches vs severity

df.sev<-sql("SELECT b.bugs.severity AS Severity, COUNT(*) AS Number  
            FROM NRPatches a LEFT JOIN bugstable b
            ON a.bug_id=b._id
            GROUP BY b.bugs.severity")
R.dfSev<-as.data.frame(df.sev)
sev.lables<-unlist(R.dfSev$Severity)
x<-R.dfSev$Number
piepercent<- round(100*x/sum(x), 2)
pie(x, labels = piepercent, main = "Severity of Patches with negative reviews",col=rainbow(length(x)))
legend("topright", sev.lables, cex = 0.8,
       fill = rainbow(length(x)))

###################################################################################################
# Time after open (TAO) for positive review patches(Time taken to write a patch for a critical bug)
df.taoPos<-sql("SELECT DATEDIFF(a.creation_time,CAST(b.bugs[0].creation_time AS DATE)) AS TAO, 
                b.bugs.severity AS Severity,a.size AS Patch_Size
                FROM PRPatches a LEFT JOIN bugstable b
                ON a.bug_id=b._id")

R.dfTaoPos<-as.data.frame(df.taoPos)
R.dfTaoPos$Severity<-unlist(R.dfTaoPos$Severity)
R.dfTaoPos.Critical<-R.dfTaoPos[R.dfTaoPos$Severity=="critical",]
x<-R.dfTaoPos.Critical$TAO
y<-R.dfTaoPos.Critical$Patch_Size
plot(x,y,main="Time Taken To Write a Positive Review Patch for a critical bug Vs Patch Size",ylab="Patch Size(LOC)",
     xlab="Time(days)",xlim = c(0.5,2000))
summary(R.dfTaoPos.Critical$TAO)


R.dfTaoPos.Normal<-R.dfTaoPos[R.dfTaoPos$Severity=="normal",]
x<-R.dfTaoPos.Normal$TAO
y<-R.dfTaoPos.Normal$Patch_Size
plot(x,y,main="Time Taken To Write a Positive Review Patch for a normal bug Vs Patch Size",ylab="Patch Size(LOC)",
     xlab="Time(days)",xlim = c(0.5,2000))
summary(R.dfTaoPos.Normal$TAO)
######################################################################################







#######################################################################################

# TAO for negative review patches(Time taken to write a patch for a critical bug)
df.taoNeg<-sql("SELECT DATEDIFF(a.creation_time,CAST(b.bugs[0].creation_time AS DATE)) AS TAO, 
                b.bugs.severity AS Severity,a.size AS Patch_Size
               FROM NRPatches a LEFT JOIN bugstable b
               ON a.bug_id=b._id")

R.dfTaoNeg<-as.data.frame(df.taoNeg)
R.dfTaoNeg$Severity<-unlist(R.dfTaoNeg$Severity)
R.dfTaoNeg.Critical<-R.dfTaoNeg[R.dfTaoNeg$Severity=="critical",]
x<-R.dfTaoNeg.Critical$TAO
y<-R.dfTaoNeg.Critical$Patch_Size
plot(x,y,main="Time Taken To Write a Negitive Review Patch for a critical bug Vs Patch Size",ylab="Patch Size(LOC)",
     xlab="Time(days)",xlim = c(0.5,2000))
summary(R.dfTaoNeg.Critical$TAO)

R.dfTaoNeg.Normal<-R.dfTaoNeg[R.dfTaoNeg$Severity=="normal",]
x<-R.dfTaoNeg.Normal$TAO
y<-R.dfTaoNeg.Normal$Patch_Size
plot(x,y,main="Time Taken To Write a Negitive Review Patch for a normal bug Vs Patch Size",ylab="Patch Size(LOC)",
     xlab="Time(days)",xlim = c(0.5,2000))
summary(R.dfTaoNeg.Normal$TAO)

### Prediction model based on bug report information: bug severity,Time taken 
# to write a patch, size of patch

install.packages("e1071")
library(e1071)

createOrReplaceTempView(spark.df.PosRev,"PRPatches")
createOrReplaceTempView(spark.df.NegRev,"NegPatches")
createOrReplaceTempView(spark.df.selectedbugs,"bugstable")

df.attrPos<-sql("SELECT a.id AS Patch_Id,b.bugs.severity AS Severity,DATEDIFF(a.creation_time,CAST(b.bugs[0].creation_time AS DATE)) AS TAO,
                a.size AS Size
               FROM PRPatches a LEFT JOIN bugstable b
               ON a.bug_id=b._id")


R.PosTrainingData<-as.data.frame(df.attrPos)
R.PosTrainingData[,"IsNegative"]<-rep(0)
R.PosTrainingData[R.PosTrainingData$TAO == -1,"TAO"]<-0

df.attrNeg<-sql("SELECT a.id AS Patch_Id, b.bugs.severity AS Severity,DATEDIFF(a.creation_time,CAST(b.bugs[0].creation_time AS DATE)) AS TAO,
                a.size AS Size
                FROM NegPatches a LEFT JOIN bugstable b
                ON a.bug_id=b._id")

R.NegTrainingData<-as.data.frame(df.attrNeg)
R.NegTrainingData[,"IsNegative"]<-rep(1)
R.NegTrainingData[R.NegTrainingData$TAO == -1,"TAO"]<-0

df.Patchdata<-rbind(R.PosTrainingData,R.NegTrainingData)
df.Patchdata$Severity<-unlist(df.Patchdata$Severity)
levels(df.Patchdata$IsNegative)<-c(0,1)
df.Patchdata$IsNegative<-factor(df.Patchdata$IsNegative)
set.seed(1234)

sampledset <- sample.int(2, nrow(df.Patchdata),replace=TRUE, prob=c(2/3,1/3))
df=data.frame(sampledset)
df.training <- df.Patchdata[sampledset==1, 2:5]
df.test <- df.Patchdata[sampledset==2, 2:4] 
df.testLabels <- df.Patchdata[sampledset==2, 5]

## Naive Bayes
model.naiveBayes<-naiveBayes(IsNegative~.,data=df.training)
predict.naiveBayes<-predict(model.naiveBayes,df.test,type="class")
print(table(predict.naiveBayes,df.testLabels))






sparkR.session.stop()




