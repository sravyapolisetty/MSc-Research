#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun May 14 17:21:20 2017

@author: root
"""

import pymysql
pymysql.install_as_MySQLdb()
import pandas as pd
import nltk
from pprint import pprint
import re

filename='/Users/sravyapolisetty/Desktop/Personal/Password.txt'
fileIN = open(filename, "r")
line = fileIN.readline()


db_connection=pymysql.connect(host='localhost',user='root',password=line,db='RTC')


#
#def remove_characters(text,keep_apostrophe=False):
#    
#    if keep_apostrophe:
#        PATTERN=r'[?|$|&|*|%|@|(|)|~|\r|\n|#|^0-9|;|:]'
#        filtered_text=re.sub(PATTERN,r'',text)
#        
#    else:
#        PATTERN=r'[^a-zA-Z0-9]'
#        filtered_text=re.sub(PATTERN,r'',text)
#    
#    filtered_text=" ".join(filtered_text.split())
#    return filtered_text
#
#
#def tokenize_text(text):
#    sentences=nltk.sent_tokenize(text)
#    word_tokens=[nltk.word_tokenize(sentence) for sentence in sentences]
#    return word_tokens



    

try:
    dfFiles = pd.read_sql('SELECT file FROM WI_JAVA', con=db_connection)
    
    df1=dfFiles['file'].str.rsplit('/',1)
    
    
    
    str(dfFiles[:1])
    
    
    
    
    
finally:
    db_connection.close()
    
    

