################## Contribution of bug attributes in predicting the bug CC list ######

Exploratory Analysis on the New Data Set

Setting SPARK environment, starting SPARK session and reading data from MongoDB via SPARK-MONGO connector

Sys.setenv(SPARK_HOME = "/usr/local/Cellar/apache-spark/2.1.0/libexec/")
.libPaths(c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib"), .libPaths()))

library(SparkR)
library(graphics)
library(plotrix)

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

df.temp<-sql("SELECT bg_id,severity,priority,DATEDIFF(from_unixtime(unix_timestamp(last_change_time, 'yyyy'), 'yyyy'),
from_unixtime(unix_timestamp(creation_time, 'yyyy'), 'yyyy')) AS Resolution_Time,comment_count,product
             FROM bugs")
R.dftemp<-as.data.frame(df.temp)


df.merge1<-merge.data.frame(R.dftemp, R.dftemp1)
df.merge2<-merge(df.merge1,R.dftemp2)
df.Final<-merge(df.merge2,R.dftemp3)

df.Final$severity<-as.factor(df.Final$severity)
levels(df.Final$severity)<-seq(1:7)


df.Final$priority<-as.factor(df.Final$priority)
levels(df.Final$priority)<-seq(0:5)


################# Multiple Linear Regression #############

library(stats)

#### Product: firefox

df.firefox<-df.Final[df.Final$product=='firefox',]
model1<-lm(formula = CC_Count ~  Resolution_Time + comment_count + Block_Count,
   data =df.firefox)

summary(model1)
##0.1225

model2<-lm(formula = CC_Count ~  severity + comment_count + Block_Count,
           data =df.firefox)

summary(model2)

## 0.1075

model3<-lm(formula = CC_Count ~  severity + priority + comment_count + Block_Count,
           data =df.firefox)

summary(model3)

## 0.1081

model4<-lm(formula = CC_Count ~  comment_count + Depend_Count+ Resolution_Time+Block_Count,
           data =df.firefox)

summary(model4)

model5<-model4<-lm(formula = CC_Count ~  severity + priority + comment_count,Resolution_Time,
                   data =df.firefox)

## 1 for all other combinations


### Product: Core


### Product: firefox os


### Product: toolkit


### Product: firefox for android


### cloud services


## thunderbird

## seamonkey


## firefox for metro


## mailnews core



## android background services

sort(unique(df.Final$product))

aov1 = aov(CC_Count ~ priority, data=df.Final[df.Final$product=='seamonkey',])
summary(aov1)

df<-df.Final[df.Final$product=='Boot2Gecko',]
cor(df$CC_Count,df$Resolution_Time, method = c("pearson"))








# P very less

################################
aov2 = aov(CC_Count ~ priority, data=df.firefox)
summary(aov2)
p=0.0269

###############################

cor(df.firefox$CC_Count,df.firefox$Resolution_Time)
# 0.237

############################

cor(df.firefox$CC_Count,df.firefox$comment_count)
# 0.2655

#############################




df<-df.Final[df.Final$product=='mailnews core',]
cor(df$CC_Count,df$comment_count, method = c("pearson"))


# firefox for android
# toolkit
# cloud services
# firefox for metro
# 
# seamonkey
# android background services
# mailnews core




# 1!!

#########################

chi(df.firefox$CC_Count,df.firefox$Block_Count)

# 0.23


####### correlation analysis for core #######
df.core<-df.Final[df.Final$product=="core",]
aov1 = aov(CC_Count ~ severity, data=df.core)
summary(aov1)
# P very less

################################
aov2 = aov(CC_Count ~ priority, data=df.core)
summary(aov2)
##p very less
###############################

cor(df.core$CC_Count,df.core$Resolution_Time)
# 0.212

############################

cor(df.core$CC_Count,df.core$comment_count)
# 0.18

#############################

cor(df.core$CC_Count,df.core$Depend_Count)
# 1!!

#########################

cor(df.core$CC_Count,df.core$Block_Count)

# 0.37
#########################


####### correlation analysis for firfox os #######
df.firefox.os<-df.Final[df.Final$product=="firefox os",]
aov1 = aov(CC_Count ~ severity, data=df.firefox.os)
summary(aov1)
# 0.959

################################
aov2 = aov(CC_Count ~ priority, data=df.firefox.os)
summary(aov2)
##p=0.034
###############################

cor(df.core$CC_Count,df.core$Resolution_Time)
# 0.212

############################

cor(df.core$CC_Count,df.core$comment_count)
# 0.18

#############################

cor(df.core$CC_Count,df.core$Depend_Count)
# 1!!

#########################

cor(df.core$CC_Count,df.core$Block_Count)

# 0.37
#########################

df.firefox.os<-df.Final[df.Final$product=="firefox os",]

###degrees of blockiness

nrow(df.Final)# Total bugs
nrow(df.Final[df.Final$Block_Count>=7,])


## Percentage of blockiness
#1
nrow(df.Final[df.Final$product=="toolkit" & df.Final$Block_Count>=7,])/nrow(df.Final[df.Final$product=="toolkit",])*100

#2

#3

#4

#5

#6

#>7





sort(unique(df.Final$Block_Count))
