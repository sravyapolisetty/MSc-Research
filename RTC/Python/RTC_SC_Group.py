#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Thu Jul 20 20:25:31 2017

@author: root
"""

import sys
import os
from distutils.dir_util import copy_tree
#import shutil


try:   
    sc_fullpath_count=0
    total_folder_count=0
    no_path=0
    parent_dir="/Users/sravyapolisetty/Desktop/RTC_BaseLine"
    new_dir="/Users/sravyapolisetty/Desktop/Dummy"
    misc_dir="/Users/sravyapolisetty/Desktop/Dummy/misc"
       
    
    if not os.path.exists(new_dir):
        os.makedirs(new_dir)
        
    for root, dirs, files in os.walk(parent_dir, topdown=False):
        for name in dirs:
            total_folder_count=total_folder_count+1
            if '\\' in name:
               
               sc_fullpath_count=sc_fullpath_count+1
               for root_1, dirs_1, files_1 in os.walk(new_dir, topdown=False):
                       package_name=str(name.split('\\',2)[1]) 
                       
                       if not os.path.exists(os.path.join(new_dir,package_name)):
                                    os.makedirs(os.path.join(new_dir,package_name)) 
                       
                       copy_tree(os.path.join(root,name),os.path.join(new_dir,package_name))
            
            
            else:
                if not os.path.exists(misc_dir):
                    os.makedirs(misc_dir)
                copy_tree(os.path.join(root,name),misc_dir)
             
               
    print('Total Number of Source Code Files:' + str(total_folder_count))
    print('Total Number of Source Code Files With Full Path:' +str(sc_fullpath_count))
    print('Total Number of Source Code Files With No Path:' +str(no_path))
                
          
except Exception, err:
    sys.stderr.write('Exception Error: %s' % str(err))
                 