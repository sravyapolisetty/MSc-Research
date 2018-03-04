#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Apr 29 13:47:37 2017

@author: Sravya Polisetty
"""

import io
import os
import lxml.etree as ET
import xml.etree.cElementTree as xmlET

outputxmlRoot = xmlET.Element("DOORS")
path = '/Users/sravyapolisetty/Desktop/RTC/ExtractedData/sravya_testcases_RQM'

   
for filename in os.listdir(path):
    if not filename.endswith('.xml'): continue
    tcId=''
    tcRelease=''
    tcTitle=''
    tcDescription=''
    tcDesign=''
    tcProcedure=''
    tcExpectedResult=''
    
    fullname = os.path.join(path, filename)
    parser = ET.XMLParser(ns_clean=True,recover=True)
    dom = ET.parse(fullname, parser)
    
    xslt='''<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" indent="no"/>
    
    <xsl:template match="/|comment()|processing-instruction()">
        <xsl:copy>
          <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="*">
        <xsl:element name="{local-name()}">
          <xsl:apply-templates select="@*|node()"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="@*">
        <xsl:attribute name="{local-name()}">
          <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>
    </xsl:stylesheet>
    '''
    ## Transforming XML to remove namespaces
    xslt_doc=ET.parse(io.BytesIO(str.encode(xslt)))
    transform=ET.XSLT(xslt_doc)
    tree=transform(dom)
    
    ## Root Element
    root=tree.getroot()
    
    
    ## Test Case Id
    for webId in root.findall('webId'):
        tcId=webId.text
        print(tcId)
        
    ## Test Case Title
    for title in root.findall('title'):
        tcTitle=title.text
    
    ## Test Case Description    
    for description in root.findall('description'):
        tcDescription=description.text
        
    ## Test Case Design
    for testCaseDesign in root.findall(".//*[@extensionDisplayName='RQM-KEY-TC-DESIGN-TITLE']"):
        tcDesign='. '.join(testCaseDesign.itertext())
        
    ## Test Case Procedure    
    for procedure in root.findall(".//*[@extensionDisplayName='Procedure']"):
        tcProcedure='. '.join(procedure.itertext())
        print(tcProcedure)
        
       
        
    ## Test Case Expected Results    
    for expectedResult in root.findall(".//*[@extensionDisplayName='RQM-KEY-TC-EXP-RESULTS-TITLE']"):
        tcExpectedResult='. '.join(expectedResult.itertext())
     
    for release in root.findall("category[@term='Planned For Milestone']"):
        tcRelease=release.get('value')
        
        
    testcase = xmlET.SubElement(outputxmlRoot, "testcase")
    xmlET.SubElement(testcase, "id").text = tcId
    xmlET.SubElement(testcase, "plannedFor").text=tcRelease
    xmlET.SubElement(testcase, "title").text = tcTitle
    xmlET.SubElement(testcase, "description").text = tcDescription
    xmlET.SubElement(testcase, "design").text = tcDesign              
    xmlET.SubElement(testcase, "testCaseprocedure").text = tcProcedure
    xmlET.SubElement(testcase, "expectedResult").text = tcExpectedResult
    
                    
                    
    outputTree = xmlET.ElementTree(outputxmlRoot)
    outputTree.write("/Users/sravyapolisetty/Desktop/RTC/ExtractedData/TestCases_Python_Output.xml")
    #outputTree.write("/Users/sravyapolisetty/Desktop/Test.xml")
    
    
    
     
