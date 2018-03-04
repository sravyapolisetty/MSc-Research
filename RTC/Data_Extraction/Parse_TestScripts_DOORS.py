#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Apr 29 15:10:11 2017

@author: Sravya Polisetty
"""

import io
import os
import lxml.etree as ET
import xml.etree.cElementTree as xmlET

outputxmlRoot = xmlET.Element("DOORS")

path = '/Users/sravyapolisetty/Desktop/RTC/ExtractedData/sravya_testscripts'

# Iterate through each xml file spitted by the RQMUrlUtility and get the fields we are interested in into a single xml file.
for filename in os.listdir(path):
    
    tcId=''
    tcTitle=''
    tcDescription=''
    tcSteps=''
    
    if not filename.endswith('.xml'): continue
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
    print(tree)
    
    ## Root Element
    root=tree.getroot()
    
    ## Test Script Id
    for webId in root.findall('webId'):
        tcId=webId.text
        
        
    ## Test Script Title
    for title in root.findall('title'):
        tcTitle=title.text
        if tcTitle is not None:
            tcTitle=tcTitle.replace(',','')
    
    ## Test Script Description    
    for description in root.findall('description'):
        tcDescription=description.text
        
        if tcDescription is not None:
            tcDescription=tcDescription.replace(',','')
            tcDescription=tcDescription.strip()
        
    ## Test Case Steps    
    for procedure in root.findall('steps'):
        tcSteps='. '.join(procedure.itertext())
        if tcSteps is not None:
            tcSteps=tcSteps.replace(',','')
            
        
    testscript = xmlET.SubElement(outputxmlRoot, "testscript")
    xmlET.SubElement(testscript, "id").text = tcId
    xmlET.SubElement(testscript, "title").text = tcTitle
    xmlET.SubElement(testscript, "description").text = tcDescription   
    xmlET.SubElement(testscript, "steps").text = tcSteps
                    
    outputTree = xmlET.ElementTree(outputxmlRoot)
    outputTree.write("/Users/sravyapolisetty/Desktop/TestScripts_Python_Output.xml")

