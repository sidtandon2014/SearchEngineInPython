# -*- coding: utf-8 -*-

import pymssql as mssql
import pdb
class Searcher:
    def __init__(self,serverName,dbName,userName,password):
        self.con = mssql.connect(server = serverName,database = dbName,user= userName,password = password)    
                
    def __del__(self):
        self.con.close()
    
    def dbCommit(self):
        self.con.commit()
        
    def getMatchRows(self,query):
        fieldlist='w0.urlid'
        tablelist=''  
        clauselist=''
        wordids=[]
        
        # Split the words by spaces
        words=query.split(' ')  
        tablenumber=0
        
        for word in words:
            # Get the word ID
            cursor = self.con.cursor()
            cursor.execute("select id from wordlist where words='%s'" % word)
            wordrow = cursor.fetchone()
            
            if wordrow!=None:
                wordid=wordrow[0]
                wordids.append(wordid)
                if tablenumber>0:
                    tablelist+=','
                    clauselist+=' and '
                    clauselist+='w%d.urlid=w%d.urlid and ' % (tablenumber-1,tablenumber)
                fieldlist+=',w%d.location' % tablenumber
                tablelist+='wordlocation w%d' % tablenumber      
                clauselist+='w%d.wordid=%d' % (tablenumber,wordid)
                tablenumber+=1
        
        try:
        # Create the query from the separate parts
            fullquery='select %s from %s where %s' % (fieldlist,tablelist,clauselist)
            print(fullquery)
            cursor.execute(fullquery)
            resultSet = cursor.fetchall()
            rows=[row for row in resultSet]
        except:
            print("Error in query")
                    
        return rows,wordids

    def getScoredList(self,rows,wordIds, weightFunction):
        totalScores = dict([(row[0],0) for row in rows])
        #pdb.set_trace()
        weights = [(1.0,wghtFn(rows)) for wghtFn in weightFunction]
    
        for (weight,scores) in weights:
            for url in totalScores:
                totalScores[url] += weight * scores[url]
        
        return totalScores
        
    def getURLName(self,id):
        cursor = self.con.cursor()
        cursor.execute("SELECT URL FROM dbo.URLList WHERE ID = '%s'" % id)
        row = cursor.fetchone()
        if row != None:
            return row[0]
        return None
            
    def query(self,q,weightFunction):
        rows,wordsids = self.getMatchRows(q)
        scores = self.getScoredList(rows,wordsids,weightFunction = weightFunction)
        rankedScores = sorted([(score,url) for (url,score) in scores.items()], reverse = 1)
        for (score,urlId) in rankedScores[0:10]:
            print("%f\t%s" % (score,self.getURLName(urlId)))
            
    def normalizeScores(self,scores,smallIsBetter = 0):
        vSmall = .00001
        if smallIsBetter == 0:
            maxVal = max(scores.values())
            for item in scores:
                scores[item] = scores[item]/max(maxVal,vSmall)
        else:
            minVal = min(scores.values())
            for item in scores:
                scores[item] = minVal/max(scores[item],vSmall)
        return scores

    def frequencyScores(self,rows):
        scores = dict([(row[0],0) for row in rows])
        for row in rows:
            scores[row[0]] += 1
        return self.normalizeScores(scores)

    def locationScore(self,rows):
        scores = dict([(row[0],10000000) for row in rows])
        for row in rows:
            loc = sum(row[1:])
            if loc < scores[row[0]]:
                scores[row[0]] = loc
        return self.normalizeScores(scores,1)

    def wordDistance(self,rows):
        if len(rows[0]) <= 2: 
            return dict([(row[0],1.0) for row in rows])
            
        distance = dict([(row[0],10000000) for row in rows])
        
        for row in rows:
            dist = sum([abs(row[i] - row[i-1]) for i in range(2,len(row))])
            if dist < distance[row[0]]:
                distance[row[0]] = dist
                
        return self.normalizeScores(distance,1)
                
    def inboundLinksScore(self,rows):
        scores = dict([(row[0],0) for row in rows])
        for row in rows:
            cursor = self.con.cursor()
            cursor.execute("SELECT COUNT(*) FROM [dbo].[Links] WHERE [ToID] = %d" % row[0])
            result = cursor.fetchone()
            #pdb.set_trace()
            if result != None:
                scores[row[0]] = result[0]
        return self.normalizeScores(scores)
            
    """
    With Inbound link score someone can set up the sites which point to this 
    and hence increases the score. 
    There is the need to implement page rank algorithm which give more weightage
    to sites which are already referred by some other sites
    """
    def calcualtePageRank(self,iterations = 20):
        
        cursor = self.con.cursor()
        cursor.execute("SELECT URLId,Score FROM [dbo].[PageRank]")
        resultSet = cursor.fetchall()
        
        """
        Store data in following fashoin dict(url,[pageRank,totalLinks])
        """
        dataset = dict([(row[0],[row[1],0]) for row in resultSet])
        for index in range(iterations):
            for row in resultSet:
                pageRank = 0.0
                cursor.execute("SELECT DISTINCT FromId FROM [dbo].[Links] WHERE [ToID] = %d" % row[0])
                fromLinkIds = cursor.fetchall()
                
                for (fromId,) in fromLinkIds:
                    if dataset[fromId][1] == 0:
                        cursor.execute("SELECT COUNT(*) FROM [dbo].[Links] WHERE [FromID] = %d" % fromId)
                        (val,) = cursor.fetchone()
                        dataset[fromId][1] = val
                    
                    pageRank += dataset[fromId][0]/dataset[fromId][1]
                
                pageRank = pageRank * .85 + .15
                
                dataset[row[0]][0] = pageRank
                
                #--------Update database
                cursor.execute("UPDATE dbo.PageRank SET Score = %f WHERE URLId = %d" % (pageRank,row[0]))
                print("Updated score for URLID: %s" % row[0])
                self.dbCommit()
                
    def pageRankScore(self,rows):
        pageRanks = dict([(row[0],0) for row in rows])
        for row in rows        :
            cursor = self.con.cursor()
            cursor.execute("SELECT Score from dbo.PageRank WHERE URLID = %d" % row[0])
            (val,) = cursor.fetchone()
            pageRanks[row[0]] = val 
        return self.normalizeScores(pageRanks)
            
        