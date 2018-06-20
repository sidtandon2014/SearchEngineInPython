# -*- coding: utf-8 -*-
"""
Created on Wed Jun  6 18:52:06 2018

@author: sitandon
"""
#import sys
#sys.path.append("F:\Sid\Learnings\Python\Collective Intelligence by Toby\Code\chapter4\SearchEngine_Practice")


from Crawler_Prac import crawler
from Searcher import Searcher

RUN_CRAWLER = 0

if RUN_CRAWLER == 1:
    crawler = crawler(".","SearchEngine","username","Password")
    crawler.crawl(["https://en.wikipedia.org/wiki/Google"],depth = 2)
    

searcher = Searcher(".","SearchEngine","username","Password")
searcher.query("india hyderabad",[searcher.inboundLinksScore,searcher.pageRankScore,searcher.frequencyScores])
    

