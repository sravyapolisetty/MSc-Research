#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Tue Jul 25 17:21:23 2017

@author: Sravya Polisetty

To massage the Wiki dump by removing the html tags, Non-ASCII characters and stripping white space.


"""

import os
import re
import unicodedata



raw_dir="/Volumes/Transcend/raw.en/"
IBM_Corpus="/Volumes/Transcend/IBM_Wiki_Corpus.txt"
file_count=0

def cleanhtml(raw_html):
  cleanr = re.compile('<.*?>')
  cleantext = re.sub(cleanr, '', raw_html)
  return cleantext

if not os.path.exists(raw_dir):
    print("Raw Wiki Files Missing")
    raise Exception()

if not os.path.exists(IBM_Corpus):
    print("IBM Corpus File Missing")
    raise Exception()

else:
    print("Reading wiki files....")
    for filename in os.listdir(raw_dir):
        with open(os.path.join(raw_dir,filename)) as f:
            data=f.read()
        data_cleaned=cleanhtml(data)
        data_decode_non_ASCII=unicodedata.normalize('NFKD',unicode(data_cleaned,"ISO-8859-1")).encode("ascii","ignore")
        data_remove_stray=re.sub('ENDOFARTICLE'," ",data_decode_non_ASCII)
        data_alpha_numeric=re.sub('\W+',' ', data_remove_stray)
        file_count=file_count+1
        print("Processed File Count:" + str(file_count))
       
        with open(IBM_Corpus, "a") as f:
            f.write(data_alpha_numeric)
        print("Appended to IBM Corpus")
        
        
               
        
        

