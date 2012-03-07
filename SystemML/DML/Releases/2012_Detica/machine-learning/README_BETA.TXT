___________________________________________________________________________________________

SystemML software is "Beta" and is not intended for production use.

 ---------------------------------------------------------------- 
 Product(s):                                                      
     SystemML                                           
                                                                  
 (C) Copyright IBM Corp.  2012                              
 All rights reserved.                                             
                     
                                                                  
 Licensed Materials-Property of IBM                               
 ---------------------------------------------------------------- 

Build: 2012-03-16 

Content
=======
1. FILES/DIRECTORY - DML USERS GUIDE, DML EXAMPLES, Configuration, Executable
2. USE SystemML
3. DATA IN HDFS

1. FILES/DIRECTORY
******************

README_BETA.TXT                // This file
DML.html                       // DML users guide
DMLScripts/                    // Directory with DML examples
  descriptives/                // Directory with dml scripts that compute various univariate and bivariate statistics
  GNMF.dml                     // GNMF for matrix factoring
  hello.dml                    // Simple Hello World 
  HITS.dml                     // HiTS
  kMeans.dml                   // KMEANS
  L2SVM.dml                    // L2SVM
  linearLogReg.dml			   // Linear logistic regression
  LinearRegression.dml         // Linear Regression
  PageRank.dml                 // PageRank
  rand.dml                     // Random Matrix Generation
  SeqMiner.dml				   // Sequence Miner
SystemML-config.xml            // configuration files
SystemML.jar                   // jar file for hadoop to execute

2. USE SystemML
***************

$ hadoop jar SystemML.jar 		            // display usage
$ hadoop jar SystemML.jar -f <dmlscript>	// compile and run DML script
                                            // each DML script contains more details

3. DATA IN HDFS
***************

SystemML assumes data files in HDFS. Use "hadoop fs" commands to ls/mv/cp/rm  ... data files.

$ hadoop fs    // display help

$ hadoop fs -ls 
drwxr-xr-x   - dmluser1 supergroup          0 2010-10-18 11:13 /user/dmluser1/A.data

$ hadoop fs -copyToLocal A.data .
$ hadoop fs -copyFromLocal A.data .

