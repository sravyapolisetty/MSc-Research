#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Tue Jul 18 17:44:13 2017

@author: Sravya Polisetty

- Reads a json with fields 'Test Case Id', 'Source Code File' and 'Text'
- Cleans the Text Field
- Creates folders with name as unique source code file name
- Each folder will have text file consisting of the mapped test case (Test Case Id as name of the text file and
  cleaned 'Text' content in the txt file) 
- The final directory is used for bag of words classification using Weka tool.
"""

import json
import sys
import os
import HTMLParser
import codecs
#import unicodedata
from bs4 import BeautifulSoup


html_parser = HTMLParser.HTMLParser()

try:   
    
    parent_dir="/Volumes/Transcend/RTC_BaseLine"
    if not os.path.exists(parent_dir):
        os.makedirs("/Volumes/Transcend/RTC_BaseLine")
        
    with codecs.open("/Users/sravyapolisetty/Desktop/Output.json") as json_data:
        
        data = json.load(json_data)
        folder_count=0
        file_count=0
        for i in data:
            foldername=i['Source_Code_File']
            foldername=foldername.replace('/','\\')
            filename=str(i['Test_Case_Id'])+".txt"
        
            if not os.path.exists(parent_dir+"/"+foldername):
                os.makedirs(parent_dir+"/"+foldername)
                folder_count=folder_count+1
                print("Folder Count:" +str(folder_count))
              
            if not os.path.exists(parent_dir+"/"+foldername+"/"+filename):
                with codecs.open(parent_dir+"/"+foldername+"/"+filename,"w", encoding='utf8') as text_file:
                    original_text=i['Text']
                    'Escaping HTML characters'
                    #testCase_Text= html_parser.unescape(original_text)
                    testCase_Text=BeautifulSoup(original_text)
                    #testCase_Text= unicodedata.normalize('NFD', original_text).encode('ascii', 'ignore')
                    text_file.write(testCase_Text.text)
                    file_count=file_count+1
                    print("File Count:" +str(file_count))
                        
                        
        
        print("Number of Unique Source Code Files" +str(folder_count))
        
        
except Exception, err:
    sys.stderr.write('Exception Error: %s' % str(err))

