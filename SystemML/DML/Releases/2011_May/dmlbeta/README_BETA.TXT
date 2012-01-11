WELCOME TO THE IBM SYSTEMML INTERNAL BETA. 

This is IBM CONFIDENTIAL.

Date:  2011-05-19 
Build: 2011-05-19 

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

$ dml			    // display usage
$ dml <dmlscript>	// compile and run DML script


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

Browse HDFS filesystem:

$ firefox http://dml1.almaden.ibm.com:50198/browseDirectory.jsp?dir=/user/dmluser1&namenodeInfoPort=51070


6. DML EXAMPLES
***************

gnmf.dml
  with data in hdfs:
     gnmf/in/v
     gnmf/in/h
     gnmf/in/w

hits.dml
  with data in hdfs:
     hits/in/graph
     hits/in/authorities

linear_regression.dml
  with data in hdfs:
     linear_regression/in/v
     linear_regression/in/y

pagerank.dml
  with data in hdfs:
     pagerank/in/g	
     pagerank/in/p	
     pagerank/in/e	
     pagerank/in/u	
   
descriptives.dml
  with data in hdfs:
     descripives/in/x

linearLogReg.dml
  uses data that is generated randomly
  
descriptives
  scripts to compute univariate and bivariate statistics for scale, nominal, and ordinal variables.
  