## This SQL script file is used to create a db and db objects on MySQL and load the extracted RTC data into it ####
###################################################################################################################

CREATE DATABASE RTC;

USE RTC;

############## New Story Test ##########################

CREATE TABLE NewStoryTest (
    id INT NOT NULL PRIMARY KEY,
    plannedfor VARCHAR(50),
    summary LONGTEXT,
    description LONGTEXT,
    parent  INT
    
) ;

LOAD XML LOCAL INFILE  '//users//sravyapolisetty//Desktop//RTC//Extracted Data//TC.xml' 
INTO TABLE NewStoryTest ROWS IDENTIFIED BY  '<testcase>' ;

SELECT * FROM  NewStoryTest ;

################### New Story Test  Comments ################

CREATE TABLE NSTComments (
    uid INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	commentText LONGTEXT,
	creationDate datetime,
    creator VARCHAR(100),
    workItem INT
    
) ;

LOAD XML LOCAL INFILE  '//users//sravyapolisetty//Desktop//RTC//ExtractedData//Comments.xml'
INTO TABLE NSTComments ROWS IDENTIFIED BY  '<comment>' ;

SELECT * FROM NSTComments;


########## ################ Work Items ######################
CREATE TABLE WorkItems (
    uid INT NOT NULL AUTO_INCREMENT,
    id INT NOT NULL ,
    plannedFor VARCHAR(50),
    file LONGTEXT,
    createdYear int,
    parent INT,
    PRIMARY KEY (uid)
) ;


LOAD XML LOCAL INFILE  '//users//sravyapolisetty//Desktop//RTC//Extracted Data//WI_RMP_Defects.xml' 
INTO TABLE WorkItems ROWS IDENTIFIED BY  '<workitem>' ;

UPDATE WorkItems SET createdYear=0 WHERE createdYear IS NULL;



SELECT *  FROM WorkItems; 

#########################################################

############## RQM Test Case parent table #################

CREATE TABLE RQMTestCase(
id INT NOT NULL,
plannedFor TEXT,
title longtext,
description LONGTEXT,
design LONGTEXT,
testCaseprocedure LONGTEXT,
expectedResult LONGTEXT

);

LOAD XML LOCAL INFILE  '//users//sravyapolisetty//Desktop//RTC//ExtractedData//TestCases_Python_Output.xml' 
INTO TABLE RQMTestCase ROWS IDENTIFIED BY '<testcase>';
 
DROP TABLE RQMTestCase;


LOAD XML LOCAL INFILE  '//users//sravyapolisetty//Desktop//RTC//ExtractedData//TestCases_Python_Output.xml' 
INTO TABLE RQMTestCase_Dummy ROWS IDENTIFIED BY '<testcase>';
 
############## RQM Test Script parent table ############
CREATE TABLE RQMTestScript(
id INT,
title longtext,
description LONGTEXT,
steps LONGTEXT
);

LOAD XML LOCAL INFILE  '//users//sravyapolisetty//Desktop//RTC//ExtractedData//TestScripts_Python_Output.xml' 
INTO TABLE RQMTestScript ROWS IDENTIFIED BY '<testscript>';

##DROP TABLE RQMTestScript;

SELECT * FROM RQMTestScript;

########## RQM Test Cases With Story Mapping  #############

CREATE TABLE RQMTestCase_StoryMapping (
    storyId INT NOT NULL ,
    testcaseId LONGTEXT
   
) ;

## Load data from TestCase-Story Mapping.csv

SELECT *  FROM RQMTestCase_StoryMapping;

##DROP TABLE RQMTestCase_StoryMapping;


########### RQM  Test Cases With Defect Mappping ########

CREATE TABLE RQMTestCase_DefectMapping(
UID INT PRIMARY KEY auto_increment,
ID INT NOT NULL,
Title LONGTEXT,
Defect LONGTEXT
);

LOAD XML LOCAL INFILE '/users//sravyapolisetty//Desktop//convertcsv.xml' 
INTO TABLE RQMTestCase_DefectMapping ROWS identified by '<testcase>';

##DROP TABLE RQMTestCase_DefectMapping;



###########  RQM Test Cases With Test Script Mapping #######

CREATE TABLE RQMTestCase_TestScriptMapping(
TestCaseID INT NOT NULL,
TestScriptID INT
);

LOAD DATA LOCAL INFILE '/users//sravyapolisetty//Desktop//RTC//ExtractedData//Test Case-Test Script.csv' 
INTO TABLE RQMTestCase_TestScriptMapping FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\r\n' (TestCaseID,TestScriptID);

SELECT * FROM RQMTestCase_TestScriptMapping;

UPDATE RQMTestCase_TestScriptMapping SET TestScriptID=NULL where TestScriptID=0;






###########################################################################


DELIMITER $$


CREATE FUNCTION strSplit(x VARCHAR(65000), delim VARCHAR(12), pos INTEGER) 
RETURNS VARCHAR(65000)
BEGIN
  DECLARE output VARCHAR(65000);
  SET output = REPLACE(SUBSTRING(SUBSTRING_INDEX(x, delim, pos)
                 , LENGTH(SUBSTRING_INDEX(x, delim, pos - 1)) + 1)
                 , delim
                 , '');
  IF output = '' THEN SET output = null; END IF;
  RETURN output;
END $$


CREATE PROCEDURE ExplodeTable()
BEGIN
  DECLARE i INTEGER;

  SET i = 1;
  REPEAT
    INSERT INTO RQMTestCase_Defect (ID, Title,Defect)
      SELECT ID, Title,strSplit(Defect, ',', i) FROM RQMTestCase_DefectMapping;
    SET i = i + 1;
    UNTIL ROW_COUNT() = 0
  END REPEAT;
END $$

DELIMITER ;

USE RTC;



CREATE TABLE RQMTestCase_Defect(
UID INT PRIMARY KEY auto_increment,
ID INT NOT NULL,
Title LONGTEXT,
Defect LONGTEXT
);

DROP TABLE RQMTestCase_Defect;

CALL ExplodeTable();

SELECT * FROM RQMTestCase_DefectMapping WHERE ID=188;






##############################################################


SELECT * FROM  NewStoryTest ;

SELECT * FROM NSTComments;

SELECT *  FROM WorkItems; 

SELECT * FROM RQMTestCase;

SELECT * FROM RQMTestScript;

SELECT *  FROM RQMTestCase_StoryMapping;

SELECT * FROM RQMTestCase_DefectMapping;


SELECT * FROM RQMTestCase_TestScriptMapping;





