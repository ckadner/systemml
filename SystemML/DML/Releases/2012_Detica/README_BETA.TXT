___________________________________________________________________________________________

SystemML software is "Beta" and is not intended for production use.

 ---------------------------------------------------------------- 
 Product(s):                                                      
     SystemML                                           
                                                                  
 (C) Copyright IBM Corp.  2012                              
 All rights reserved.                                             
                     
                                                                  
 Licensed Materials-Property of IBM                               
 ---------------------------------------------------------------- 

Build: 2012-02-08 

Content
=======
1. DIRECTORY
2. USERS GUIDE
3. USE SystemML
4. STARTER EXAMPLES
5. DATA IN HDFS
6. DML EXAMPLES


1. FILES/DIRECTORY
******************

README_BETA.TXT               // This file
DML.html                      // DML users guide
descriptives                  // a folder with dml scripts that compute various univariate and bivariate statistics
gnmf.dml                      // GNMF
hello.dml                     // Hello World
hits.dml                      // HiTS
linear_regression.dml         // Linear Regression
pagerank.dml                  // PageRank
rand.dml                      // Random Matrix
linearLogReg.dml			  // Linear logistic regression


2. USERS GUIDE
**************

DML.html   


3. USE SystemML
***************

$ hadoop jar SystemML.jar 		            // display usage
$ hadoop jar SystemML.jar -f <dmlscript>	// compile and run DML script


4. STARTER EXAMPLES
*******************

hello.dml
rand.dml


5. DATA IN HDFS
***************

SystemML assumes data files in HDFS. Use "hadoop fs" commands to ls/mv/cp/rm  ... data files.

$ hadoop fs    // display help

$ hadoop fs -ls
drwxr-xr-x   - dmluser1 supergroup          0 2010-10-18 11:13 /user/dmluser1/A.data


$ hadoop fs -copyToLocal A.data .


