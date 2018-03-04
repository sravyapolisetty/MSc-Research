Sys.setenv(SPARK_HOME = "/usr/local/Cellar/apache-spark/2.1.0/libexec/")
.libPaths(c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib"), .libPaths()))

library(SparkR)
sparkR.session(sparkPackages = "com.stratio.datasource:spark-mongodb_2.11:0.12.0")
sparkR.session.stop()
#sparkR.conf("spark.executor.memory", "3g")

spark.df.selectedbugs<- read.df("",source ="com.mongodb.spark.sql.DefaultSource", 
                                uri = "mongodb://127.0.0.1/Mozilla.selectedBugs")

spark.df.changeSet<-read.df("",source ="com.mongodb.spark.sql.DefaultSource", 
                            uri = "mongodb://127.0.0.1/Mozilla.selectedChangeset")

spark.df.bugAttachments<-read.df("",source ="com.mongodb.spark.sql.DefaultSource", 
                                uri = "mongodb://127.0.0.1/Mozilla.bugAttachments")
#sparkR.session.stop()
nrow(spark.df.selectedbugs)
nrow(spark.df.changeSet)
nrow(spark.df.bugAttachments)

createOrReplaceTempView(spark.df.changeSet,"ChangeSet")
createOrReplaceTempView(spark.df.selectedbugs,"SelectedBugs")
createOrReplaceTempView(spark.df.bugAttachments,"BugAttachments")


#commit-id, bug_id, file_name, developer_name,reviewer

library(tidyr)




df1<-sql("SELECT a._id AS Commit_ID,a.bug_id AS Bug_ID,a.files AS FILE_NAME,a.user AS Developer_Name,
          a.Date AS Commit_Date
          FROM ChangeSet a LEFT JOIN BugAttachments b
          ON a.bug_id=b.bug_id")

R.df1<-as.data.frame(df1)
R.df1$FILE_NAME<-sapply(R.df1$FILE_NAME, paste, collapse = ",")
separate_rows(R.df1,FILE_NAME,convert = FALSE,sep = ",")
save(R.df1,"~/Desktop,R.df1.rda")
write.csv(R.df1,"~/Desktop/Data1.csv")

#commit-id, bug_id, blocked_bug_id

df2<-sql("SELECT a._id AS Commit_ID,a.bug_id AS Bug_ID ,b.bugs[0].blocks AS blocked_bug_id
          FROM ChangeSet a LEFT JOIN SelectedBugs b
          ON a.bug_id=b._id")
R.df2<-as.data.frame(df2)
R.df2$blocked_bug_id<-sapply(R.df2$blocked_bug_id, paste, collapse = ",")
separate_rows(R.df2,blocked_bug_id,convert = FALSE,sep = ",")
write.csv(R.df2,"~/Desktop/Data2.csv")

#commit_id, bug_id, depends_on_bug_id

df3<-sql("SELECT a._id AS Commit_ID,a.bug_id AS Bug_ID ,b.bugs[0].depends_on AS depends_on_bug_id
          FROM ChangeSet a LEFT JOIN SelectedBugs b 
         ON a.bug_id=b._id")
R.df3<-as.data.frame(df3)
R.df3$depends_on_bug_id<-sapply(R.df3$depends_on_bug_id, paste, collapse = ",")
separate_rows(R.df3,depends_on_bug_id,convert = FALSE,sep = ",")
write.csv(R.df3,"~/Desktop/Data3.csv")

##############


