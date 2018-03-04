######################FSE 2017###############

###Setting SPARK Environment####
Sys.setenv(SPARK_HOME = "/usr/local/Cellar/apache-spark/2.1.0/libexec/")
.libPaths(c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib"), .libPaths()))

##Loading Library
install.packages("zoo")
install.packages("ade4")
install.packages("ggplot2")
install.packages("tidyr")
library(dplyr)
library(lubridate)
library(zoo)
library(ade4)
library(ggplot2)
library(SparkR)
library(tidyr)

sparkR.session(sparkPackages = "com.stratio.datasource:spark-mongodb_2.11:0.12.0")

## Reading data from MongoDB

spark.df.selectedbugs<- read.df("",source ="com.mongodb.spark.sql.DefaultSource", 
                                uri = "mongodb://127.0.0.1/Mozilla.selectedBugs")

spark.df.changeSet<-read.df("",source ="com.mongodb.spark.sql.DefaultSource", 
                            uri = "mongodb://127.0.0.1/Mozilla.selectedChangeset")

spark.df.bugAttachments<-read.df("",source ="com.mongodb.spark.sql.DefaultSource", 
                                 uri = "mongodb://127.0.0.1/Mozilla.bugAttachments")


nrow(spark.df.selectedbugs)
nrow(spark.df.changeSet)
nrow(spark.df.bugAttachments)

createOrReplaceTempView(spark.df.selectedbugs, "bugstable")
createOrReplaceTempView(spark.df.changeSet,"changesettable")
createOrReplaceTempView(spark.df.bugAttachments,"bugattachmenttable")

### Plots

## Number of bugs reports quarterly from 2008-2012

df.bugstats_old<-sql("SELECT _id,bugs[0].creation_time,bugs[0].product,bugs[0].component FROM bugstable
                 WHERE YEAR(bugs[0].creation_time) BETWEEN 2008 AND 2013")
R.dfbugstats_old<-as.data.frame(df.bugstats_old)    
names(R.dfbugstats_old)<-c("bug_id","creation_time","product","component")
unique(R.dfbugstats_old$product)
R.dfbugstats_old$Quarter_Year <- as.yearqtr(as.Date(R.dfbugstats_old$creation_time), "%m/%d/%Y")
R.dfbugstats_old["BugCount"]<-0
df_agg_old <- aggregate(BugCount~product+Quarter_Year,R.dfbugstats_old,FUN=NROW)
ggplot() + geom_line(data=df_agg_old, aes(x=Quarter_Year, y=BugCount,color=product)) 
  scale_x_(format="%YQ%q", n=20)


## Number of bugs reports quarterly from 2013-2017

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

## Distribution of bug fix time
df.bugfixtime<-sql("SELECT _id,DATEDIFF(bugs[0].last_change_time,bugs[0].creation_time) AS Time FROM bugstable")
R.dfbugfixtime<-as.data.frame(df.bugfixtime)
names(R.dfbugfixtime)<-c("Bug_Id","Resolution_Time")
boxplot(R.dfbugfixtime$Resolution_Time,main="Bug Resolution Time(days)",ylab="Time(days)")

summary(R.dfbugfixtime)

## Distribution of bug for every 30 days

df.quick<-R.dfbugfixtime[R.dfbugfixtime$Resolution_Time<1000,]
df.late<-R.dfbugfixtime[R.dfbugfixtime$Resolution_Time>1000,]
#nrow(R.dfbugfixtime[R.dfbugfixtime$Resolution_Time>5000,])
hist(df.quick$Resolution_Time,breaks=seq(0,1100,30),xlab = "Resolution Time",ylab="Number of bugs",freq = TRUE,main="Distribution of bugs with resolution time less than 3 years")

hist(df.late$Resolution_Time,breaks=seq(900,6180,30),xlab = "Resolution Time",ylab="Number of bugs",freq = TRUE, main="Distribution of bugs with resolution time greater than 3 years")


### Severity and Product type of bugs with greater resolution time

df.attr<-sql("SELECT _id,bugs[0].product AS Product,bugs[0].severity AS Severity 
             FROM bugstable WHERE DATEDIFF(bugs[0].last_change_time,bugs[0].creation_time)>5000")
R.dfattr<-as.data.frame(df.attr)
###################################################################
# Bugs Vs Priority
df.bugsPriority<-sql("select _id As Bug_Id,bugs[0].priority AS Priority FROM bugstable")
R.dfbugsPriority<-as.data.frame(df.bugsPriority)
R.dfbugsPriority["Count"]<-0
df.agg<-aggregate(Count ~ Priority,data=R.dfbugsPriority,FUN=NROW)

# Bugs Vs Severity

df.bugsSeverity<-sql("select _id As Bug_Id,bugs[0].severity AS Severity FROM bugstable")
R.dfbugsSeverity<-as.data.frame(df.bugsSeverity)
R.dfbugsSeverity["Count"]<-0
df.agg<-aggregate(Count ~ Severity,data=R.dfbugsSeverity,FUN=NROW)


###################################################################

# Product

#####################################################################
## Product Vs Resolution Time

df.prodRes<-sql("SELECT bugs[0].product AS product,DATEDIFF(bugs[0].last_change_time,bugs[0].creation_time) AS Resolution_Time
                FROM bugstable")
R.dfprodRes<-as.data.frame(df.prodRes)
df_aggProd <- aggregate(. ~product,data=R.dfprodRes,mean)

ggplot() + geom_line(data=R.dfprodRes, aes(y=Resolution_Time, x=product)) 

##One-way ANOVA
R.dfprodRes$product<-as.factor(R.dfprodRes$product)
summary(aov(Resolution_Time ~ product,R.dfprodRes))

## Kruskal-Wallis Test. The results show that we have to reject the null hypothesis.
kruskal.test(Resolution_Time ~ product,data=R.dfprodRes)
######################################################################
## Product Vs Severity
df.prodSev<-sql("SELECT bugs[0].product AS product,bugs[0].severity AS severity
                FROM bugstable")
R.dfprodSev<-as.data.frame(df.prodSev)
R.dfprodSev$product<-as.factor(R.dfprodSev$product)
R.dfprodSev$severity<-as.factor(R.dfprodSev$severity)
R.dfprodSev["Count"]<-0
chisq.test(R.dfprodSev$product,R.dfprodSev$severity)
plot(table(R.dfprodSev$product,R.dfprodSev$severity),main="Product Vs Severity")
df.aggprodsev<-aggregate(Count ~ product+severity,data = R.dfprodSev,FUN=NROW)

######################################################################
## Product Vs Priority
df.prodPriority<-sql("SELECT bugs[0].product AS product,bugs[0].priority AS priority
                FROM bugstable")
R.dfprodPriority<-as.data.frame(df.prodPriority)
chisq.test(R.dfprodPriority$product,R.dfprodPriority$priority)
plot(table(R.dfprodPriority$product,R.dfprodPriority$priority),main="Product Vs Priority")
R.dfprodPriority["Count"]<-0
df.aggprodpr<-aggregate(Count ~ product+priority,data = R.dfprodPriority,FUN=NROW)
mosaicplot(R.dfprodPriority)
######################################################################
## Product Vs Patch Size
df.prodPatch<-sql("SELECT a.bugs[0].product AS product,b.size AS patch_size
                FROM bugstable a LEFT JOIN bugattachmenttable b
                ON a._id=b.bug_id")
R.dfprodPatch<-as.data.frame(df.prodPatch)
R.dfprodPatch$product<-as.factor(R.dfprodPatch$product)
ggplot() + geom_line(data=R.dfprodPatch, aes(y=patch_size, x=product)) 

##One-way ANOVA
R.dfprodPatch$product<-as.factor(R.dfprodPatch$product)
summary(aov(patch_size ~ product,R.dfprodPatch))

## Kruskal-Wallis Test. The results show that we have to reject the null hypothesis.
kruskal.test(patch_size ~ product,data=R.dfprodPatch)

#######################################################################
#Patch-Size 
########################################################################
# Patch-Size Vs Bug
df.psBug<-sql("SELECT bug_id,size FROM bugattachmenttable")
R.dfpsBug<-as.data.frame(df.psBug)
summary(R.dfpsBug)
boxplot(R.dfpsBug$size)
############################################################################

# Patch-Size Vs ResolutionTime
df.psRes<-sql("SELECT b.size AS patch_size,DATEDIFF(a.bugs[0].last_change_time,a.bugs[0].creation_time) AS Resolution_Time
              FROM bugstable a LEFT JOIN bugattachmenttable b
              ON a._id=b.bug_id")
R.dfpsRes<-as.data.frame(df.psRes)
plot(R.dfpsRes)
summary.lm(patch_size ~ Resolution_Time,data=R.dfpsRes)
aov(patch_size ~ Resolution_Time,R.dfpsRes)

###############################################################################

# Patch-Size Vs Priority
df.psPri<-sql("SELECT b.size AS patch_size,a.bugs[0].priority AS priority
              FROM bugstable a LEFT JOIN bugattachmenttable b
              ON a._id=b.bug_id")
R.dfpsPri<-as.data.frame(df.psPri)
plot(R.dfpsPri)

##One-way ANOVA
R.dfpsPri$priority<-as.factor(R.dfpsPri$priority)
summary(aov(patch_size ~ priority,R.dfpsPri))

## Kruskal-Wallis Test. The results show that we have to reject the null hypothesis.
kruskal.test(priority ~ patch_size,data=R.dfpsPri)
#############################################################################
# Patch-Size Vs Severity
df.psSev<-sql("SELECT b.size AS patch_size,a.bugs[0].severity AS severity
              FROM bugstable a LEFT JOIN bugattachmenttable b
              ON a._id=b.bug_id")
R.dfpsSev<-as.data.frame(df.psSev)
summary(R.dfpsSev)
ggplot() + geom_line(data=R.dfpsSev, aes(y=patch_size, x=severity)) 

#############################################################################
# Patch-Size vs Time(Year)
df.psTime<-sql("SELECT b.size AS patch_size,year(a.bugs[0].creation_time) AS Year 
              FROM bugstable a LEFT JOIN bugattachmenttable b
               ON a._id=b.bug_id")
R.dfpsTime<-as.data.frame(df.psTime)
ggplot() + geom_line(data=R.dfpsTime, aes(y=patch_size, x=Year)) 
R.dfpsTime[is.na(R.dfpsTime$patch_size),]<-0
R.dfpsTime<-R.dfpsTime[!R.dfpsTime$patch_size==0,]
df.agg<-aggregate(R.dfpsTime$patch_size, list(R.dfpsTime$Year), mean)
names(df.agg)<-c("Year","Mean_Patch_Size")
plot(df.agg,xlim=c(1998,2017),xlab = "Year",ylab="Mean Patch Size",main="Mean Patch Size Over the years")

#############################################################################
# Patch-Size Vs Product
df.psProd<-sql("SELECT b.size AS patch_size,a.bugs[0].product AS product 
              FROM bugstable a LEFT JOIN bugattachmenttable b
               ON a._id=b.bug_id")
R.dfpsProd<-as.data.frame(df.psProd)
ggplot() + geom_line(data=R.dfpsProd, aes(y=patch_size, x=product))
R.dfpsProd[is.na(R.dfpsProd$patch_size),]<-0
R.dfpsProd<-R.dfpsProd[!R.dfpsProd$patch_size==0,]
df.agg<-aggregate(R.dfpsProd$patch_size, list(R.dfpsProd$product), mean)
names(df.agg)<-c("Product","Mean_Patch_Size")
#######################################################################
# Patch-Size Vs CC Listsize

df.psCC<-sql("SELECT b.size AS patch_size,size(a.bugs[0].cc_detail) AS CC_List
              FROM bugstable a LEFT JOIN bugattachmenttable b
               ON a._id=b.bug_id")
R.dfpsCC<-as.data.frame(df.psCC)

ggplot() + geom_line(data=R.dfpsCC, aes(y=patch_size, x=CC_List),main="Patch Size Vs CC List Size") 


####################################################################
# Patch-Size Vs Rev List
df.psRevList<-sql("SELECT b.size AS patch_size,size(a.bugs[0].flags) AS Rev_List 
              FROM bugstable a LEFT JOIN bugattachmenttable b
              ON a._id=b.bug_id")
R.dfpsRevList<-as.data.frame(df.psRevList)
ggplot() + geom_line(data=R.dfpsRevList, aes(y=patch_size, x=Rev_List))

#######################################################################
# Time(Year)Vs Bug


# Time(Year) Vs ResolutionTime

# Time(Year) Vs Priority

# Time(Year) Vs Severity

# Time(Year) Vs Product

#Time(Year) Vs CC list

#Time(Year) Vs Rev List



  




########################################################################

#### Datasets from Mongo#####
#commit-id, bug_id, file_name, developer_name,commit_time

df1<-sql("SELECT _id AS Commit_ID,bug_id AS Bug_ID,files AS FILE_NAME,user AS Developer_Name,
          Date AS Commit_Date
         FROM changesettable")
R.df1<-as.data.frame(df1)
R.df1$FILE_NAME<-sapply(R.df1$FILE_NAME, paste, collapse = ",")
separate_rows(R.df1,FILE_NAME,convert = FALSE,sep = ",")
save(R.df1,file="~/Downloads/R.df1.rda")
write.csv(R.df1,"~/Downloads/Data1.csv")

#commit-id, bug_id, blocked_bug_id

df2<-sql("SELECT a._id AS Commit_ID,a.bug_id AS Bug_ID ,b.bugs[0].blocks AS blocked_bug_id
         FROM changesettable a LEFT JOIN bugstable b
         ON a.bug_id=b._id")
R.df2<-as.data.frame(df2)
R.df2$blocked_bug_id<-sapply(R.df2$blocked_bug_id, paste, collapse = ",")
separate_rows(R.df2,blocked_bug_id,convert = FALSE,sep = ",")
write.csv(R.df2,"~/Desktop/Data2.csv")

#commit_id, bug_id, depends_on_bug_id

df3<-sql("SELECT a._id AS Commit_ID,a.bug_id AS Bug_ID ,b.bugs[0].depends_on AS depends_on_bug_id,
          b.bugs[0].product AS product
         FROM changesettable a LEFT JOIN bugstable b 
         ON a.bug_id=b._id")

R.df3<-as.data.frame(df3)
R.df3$depends_on_bug_id<-sapply(R.df3$depends_on_bug_id, paste, collapse = ",")
separate_rows(R.df3,depends_on_bug_id,convert = FALSE,sep = ",")
save(R.df3,file="~/Downloads/R.df3.rda")

##############

df5<-sql("SELECT a._id AS Commit_ID,a.bug_id AS Bug_ID,DATEDIFF(b.bugs[0].last_change_time,b.bugs[0].creation_time) AS Resolution_Duration,
          b.bugs[0].last_change_time AS Resolution_Time,b.bugs[0].product AS Product 
          FROM changesettable a LEFT JOIN bugstable b 
          ON a.bug_id=b._id")
R.df5<-as.data.frame(df5)
save(R.df5,file="~/Downloads/R.df5.rda")



