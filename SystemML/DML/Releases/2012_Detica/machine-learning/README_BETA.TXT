___________________________________________________________________________________________

SystemML is a component of IBM InfoSphere BigInsights.
It is available under "Beta" license and it is not intended 
for production use yet.

(C) Copyright IBM Corp.  2012                              
 
 All rights reserved.                                             
                                                                                     
 Licensed Materials-Property of IBM                               
 ---------------------------------------------------------------- 

Build: 2012-03-20

Content
=======
1. CLASSPATH & JAVA_HOME
2. FILES & DIRECTORY
3. PUT DATA IN HDFS
4. USE SystemML to RUN DML scripts

1. CLASSPATH & JAVA_HOME
************************
Make sure you have the valid hadoop-0.20.2-core.jar in your CLASSPATH setting;
Make sure your JAVA_HOME is set to the valid jdk 1.6.

2. FILES/DIRECTORY
******************
README_BETA.TXT                // This file
DML.html                       // DML user guide
DMLScripts/                    // Directory with DML examples
  descriptives/                // Directory with DML scripts that compute various univariate and bivariate statistics
    Scale.dml                  // univariate statistics for scale data
    Categorical.dml            // univariate statistics for categorical data
    ScaleScale.dml             // bivariate statistics between scale data
    CategoricalCategorical.dml // bivariate statistics between categorical data
    ScaleCategorical.dml       // bivariate statistics between scale data and categorical data
    OrdinalOrdinal.dml         // bivariate statistics between ordinal data
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
SystemML.jar                   // SystemML jar file for hadoop to execute 
genData.dml					   // DML script for generating data on hdfs for trying DMLScripts/*.dml
runTest.sh	                   // shell script for trying DMLScripts/*.dml

3. PUT DATA IN HDFS
*******************
SystemML assumes data files in HDFS. 

You can use "hadoop fs" commands to ls/mv/cp/rm  ... data files.
$ hadoop fs        // display help
$ hadoop fs -ls    // list files and directories
$ hadoop fs -copyToLocal A.data .    // copy HDFS files to local files
$ hadoop fs -copyFromLocal A.data .  // copy local files to HDFS files

You can look and run DML script genData.dml to generate data needed

4. USE SystemML to RUN DML scripts
***********************************
$ hadoop jar SystemML.jar 		            // display usage
$ hadoop jar SystemML.jar -f <dmlscript>	// compile and run DML script
                                            // each DML script contains more details
                                            
You can look and run shell script runTest.sh for all DML scripts inside DMLScripts directory                                      
                                         


