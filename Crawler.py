# -*- coding: utf-8 -*-
"""
Created on Thu Jun  7 10:42:12 2018

@author: sitandon
"""

from bs4 import BeautifulSoup
from urllib.request import urlopen as uReq
import pymssql as mssql
import pdb
import re

class crawler:
    def __init__(self,serverName,dbName,userName,password):
        self.con = mssql.connect(server = serverName,database = dbName,user= userName,password = password)    
                
    def __del__(self):
        self.con.close()
    
    def dbCommit(self):
        self.con.commit()
    
    """
    This function will only make the entry in URLList
    So that we can get the ToId in case of LinkTable
    """
    def addURLToDB(self,url):
        cursor = self.con.cursor()
        cursor.callproc("dbo.uspAddURL",(url,))
        self.dbCommit()
    
    """
    This function will make an entry in URLList table as well as Word Table
    """
    def addToDB(self,url,soup):
        try:
            if self.isIndexed(url):
                return 
                
            cursor = self.con.cursor()
            
            self.addURLToDB(url)
            
            text = self.getTextOnly(soup)
            words = self.separateWords(text)
            for i in range(len(words)):
                cursor.callproc("dbo.uspInsertWord",(url,words[i],i))
                self.dbCommit()
        except:
            print("Error in add to DB")
        
    def getTextOnly(self,soup):
        v = soup.string
        if v == None:
            c = soup.contents
            resulttext = ""
            for t in c:
                subtext = self.getTextOnly(t)
                resulttext += subtext + "\n"
            return resulttext
        else:
            return v.strip()
        
    def separateWords(self,text):
        splitter = re.compile("\\W*")
        return [s.lower() for s in splitter.split(text) if s!= ""]
        
    def isIndexed(self,url):
        try:
            cursor = self.con.cursor()
            outputVal = cursor.callproc("dbo.isURLTraversed",(url,mssql.output(int,0)))
            if outputVal[1] == 0:
                return False
            else:
                return True
        except:
            print("Error in isIndexed")
        
    def addLinkRef(self,urlFrom,urlTo,linkText):
        try:
            cursor = self.con.cursor()
            cursor.callproc("dbo.uspInsertLinks",(urlFrom,urlTo,linkText))
            self.dbCommit()
        except:
            print("Error in addLinkRef")
    
    def crawl(self, pages, depth = 2):
        for i in range(depth):
            newpages = set()
            for page in pages:
                try:
                    uCLient = uReq(page)
                    entireHTML = uCLient.read()
                    uCLient.close()
                except:
                    print("Couldnot open the url %s", page)
                    continue
                
                page_soup = BeautifulSoup(entireHTML,"html.parser")
                links = page_soup.find_all("a")
                
                self.addToDB(page,page_soup)
                
                for link in links:
                    url = link.get("href")
                    if url != None:
                        url = url.split("#")[0] #-----Rmove location
                        
                        print("Url: %s",url)
                        
                        #--------Check for complete web path
                        if "http" in url and len(url) > 10:   
                            if not self.isIndexed(url):
                                newpages.add(url)
                            
                            self.addURLToDB(url)
                            linkText = self.getTextOnly(link)
                            self.addLinkRef(page,url,linkText)
                
                self.dbCommit()
            pages = newpages
    
