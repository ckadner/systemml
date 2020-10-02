# SystemML(Machine Learning)

SystemML is a flexible, scalable machine learning (ML) language written in Java.
SystemML's distinguishing characteristics are: (1) algorithm customizability,
(2) multiple execution modes, including Standalone, Hadoop Batch, and Spark Batch,
and (3) automatic optimization.

The latest documentation can be found at the 
[SystemML Documentation](http://sparktc.github.io/systemml/) web site.


### Algorithm Customizability

ML algorithms in SystemML are specified in a high-level, declarative machine learning (DML) language.
Algorithms can be expressed in either an R-like syntax or a Python-like syntax. DML includes
linear algebra primitives, statistical functions, and additional constructs.

This high-level language significantly increases the productivity of
data scientists as it provides (1) full flexibility in expressing custom
analytics and (2) data independence from the underlying input formats and
physical data representations.


### Multiple Execution Modes

SystemML computations can be executed in a variety of different modes. To begin with, SystemML
can be operated in Standalone mode on a single machine, allowing data scientists to develop
algorithms locally without need of a distributed cluster. Algorithms can be distributed across Hadoop or Spark.
This flexibility allows the utilization of an organization's existing resources and expertise. In addition, SystemML
can be operated via Java, Scala, and Python. SystemML also features an embedded API for scoring models.


### Automatic Optimization

Algorithms specified in DML are dynamically compiled and optimized based on data and cluster characteristics
using rule-based and cost-based optimization techniques. The optimizer automatically generates hybrid runtime
execution plans ranging from in-memory single-node execution to distributed computations on Spark or Hadoop.
This ensures both efficiency and scalability. Automatic optimization reduces or eliminates the need to hand-tune
distributed runtime execution plans and system configurations.


* * *

## Building SystemML

SystemML is built using [Apache Maven](http://maven.apache.org/).
SystemML will build on Windows, Linux, or MacOS and requires Maven 3 and Java 7 (or higher).
To build SystemML, run:

    mvn clean package


* * *

## Testing SystemML

SystemML features a comprehensive set of integration tests. To perform these tests, run:

    cd system-ml
    mvn verify 

Note: these tests require [R](https://www.r-project.org/) to be installed and available as part of the PATH variable on the machine on which you are running these tests. 

If required, please install the following packages in R:

    install.packages(c("batch", "bitops", "boot", "caTools", "data.table", "doMC", "doSNOW", "ggplot2", "glmnet", "lda", "Matrix", "matrixStats", "moments", "plotrix", "psych", "reshape", "topicmodels", "wordcloud"), dependencies=TRUE) 


* * *

## Running SystemML in Standalone Mode

SystemML can run in distributed mode as well as in local standalone mode. We'll operate in standalone mode in this guide. 
After you built SystemML from source (```mvn clean package```) the standalone mode can be executed either on Mac/Unix using the ```./bin/systemml``` script or on Windows using the ```.\bin\systemml.bat``` batch file. 

If you run from the script from the project root folder ```./``` or from the ```./bin``` folder, then the output files from running SystemML will be created inside the ```./temp``` folder to keep them separate from the SystemML source files managed by Git. The output files for all of the examples in this guide will be created under the ```./temp``` folder.

The runtime behavior and logging behavior of SystemML can be customized by editing the files ```./conf/SystemML-config.xml``` and ```./conf/log4j.properties```. Both files will be created from their corresponding ```*.template``` files during the first execution of the SystemML executable script.

When invoking the ```./bin/systemml``` or ```.\bin\systemml.bat``` with any of the prepackaged DML scripts you can omit the relative path to the DML script file. The following two commands are equivalent:

    ./bin/systemml ./system-ml/scripts/datagen/genLinearRegressionData.dml -nvargs numSamples=1000 numFeatures=50 maxFeatureValue=5 maxWeight=5 addNoise=FALSE b=0 sparsity=0.7 output=linRegData.csv format=csv perc=0.5

    ./bin/systemml genLinearRegressionData.dml -nvargs numSamples=1000 numFeatures=50 maxFeatureValue=5 maxWeight=5 addNoise=FALSE b=0 sparsity=0.7 output=linRegData.csv format=csv perc=0.5

In this guide we invoke the command with the relative folder to make it easier to look up the source of the DML scripts.


* * *

## Algorithms

SystemML features a suite of algorithms that can be grouped into five broad categories:
Descriptive Statistics, Classification, Clustering, Regression, and Matrix Factorization. Detailed descriptions of
these algorithms can be found in the Algorithm Reference packaged with SystemML.


* * *

## Linear Regression Example

As an example of the capabilities and power of SystemML and DML, let's consider the Linear Regression algorithm.
We require sets of data to train and test our model. To obtain this data, we can either use real data or
generate data for our algorithm. The [UCI Machine Learning Repository Datasets](https://archive.ics.uci.edu/ml/datasets.html)
is one location for real data. Use of real data typically involves some degree of data wrangling. In the following
example, we will use SystemML to generate random data to train and test our model.

This example consists of the following parts:

  * [Run DML Script to Generate Random Data](#run-dml-script-to-generate-random-data)
  * [Divide Generated Data into Two Sample Groups](#divide-generated-data-into-two-sample-groups)
  * [Split Label Column from First Sample](#split-label-column-from-first-sample)
  * [Split Label Column from Second Sample](#split-label-column-from-second-sample)
  * [Train Model on First Sample](#train-model-on-first-sample)
  * [Test Model on Second Sample](#test-model-on-second-sample)

SystemML is distributed in several packages, including a standalone package. We'll operate in Standalone mode in this example.

<a name="run-dml-script-to-generate-random-data" />

### Run DML(Data manuplation Language) Script to Generate Random Data

We can execute the `genLinearRegressionData.dml` script in Standalone mode using either the `systemml` or `systemml.bat` file.
In this example, we'll generate a matrix of 1000 rows of 50 columns of test data, with sparsity 0.7. In addition to this, a 51<sup>st</sup> column consisting of labels will
be appended to the matrix.

    ./bin/systemml ./system-ml/scripts/datagen/genLinearRegressionData.dml -nvargs numSamples=1000 numFeatures=50 maxFeatureValue=5 maxWeight=5 addNoise=FALSE b=0 sparsity=0.7 output=linRegData.csv format=csv perc=0.5

This generates the following files inside the ```./temp``` folder:

    linRegData.csv      # 1000 rows of 51 columns of doubles (50 data columns and 1 label column), csv format
    linRegData.csv.mtd  # metadata file


<a name="divide-generated-data-into-two-sample-groups" />

### Divide Generated Data into Two Sample Groups

Next, we'll create two subsets of the generated data, each of size ~50%. We can accomplish this using the `sample.dml` script.
This script will randomly sample rows from the `linRegData.csv` file and place them into 2 files.

To do this, we need to create a csv file for the `sv` named argument (see `sample.dml` for more details),
which I called `perc.csv`. This file was generated in previous step and looks like:

    0.5
    0.5


This will create two sample groups of roughly 50 percent each. 

Now, the `sample.dml` script can be run.

    ./bin/systemml ./system-ml/scripts/utils/sample.dml -nvargs X=linRegData.csv sv=perc.csv O=linRegDataParts ofmt=csv


This script creates two partitions of the original data and places them in a `linRegDataParts` folder. The files created are
as follows:

    linRegDataParts/1       # first partition of data, ~50% of rows of linRegData.csv, csv format
    linRegDataParts/1.mtd   # metadata
    linRegDataParts/2       # second partition of data, ~50% of rows of linRegData.csv, csv format
    linRegDataParts/2.mtd   # metadata


The `1` file contains the first partition of data, and the `2` file contains the second partition of data.
An associated metadata file describes
the nature of each partition of data. If we open `1` and `2` and look at the number of rows, we can see that typically
the partitions are not exactly 50% but instead are close to 50%. However, we find that the total number of rows in the
original data file equals the sum of the number of rows in `1` and `2`.


<a name="split-label-column-from-first-sample" />

### Split Label Column from First Sample

The next task is to split the label column from the first sample. We can do this using the `splitXY.dml` script.

    ./bin/systemml ./system-ml/scripts/utils/splitXY.dml -nvargs X=linRegDataParts/1 y=51 OX=linRegData.train.data.csv OY=linRegData.train.labels.csv ofmt=csv

This splits column 51, the label column, off from the data. When done, the following files have been created.

    linRegData.train.data.csv        # training data of 50 columns, csv format
    linRegData.train.data.csv.mtd    # metadata
    linRegData.train.labels.csv      # training labels of 1 column, csv format
    linRegData.train.labels.csv.mtd  # metadata


<a name="split-label-column-from-second-sample" />

### Split Label Column from Second Sample

We also need to split the label column from the second sample.

    ./bin/systemml ./system-ml/scripts/utils/splitXY.dml -nvargs X=linRegDataParts/2 y=51 OX=linRegData.test.data.csv OY=linRegData.test.labels.csv ofmt=csv

This splits column 51 off the data, resulting in the following files:

    linRegData.test.data.csv        # test data of 50 columns, csv format
    linRegData.test.data.csv.mtd    # metadata
    linRegData.test.labels.csv      # test labels of 1 column, csv format
    linRegData.test.labels.csv.mtd  # metadata


<a name="train-model-on-first-sample" />

### Train Model on First Sample

Now, we can train our model based on the first sample. To do this, we utilize the `LinearRegDS.dml` (Linear Regression
Direct Solve) script. Note that SystemML also includes a `LinearRegCG.dml` (Linear Regression Conjugate Gradient) algorithm 
for situations where the number of features is large.

    ./bin/systemml ./system-ml/scripts/algorithms/LinearRegDS.dml -nvargs X=linRegData.train.data.csv Y=linRegData.train.labels.csv B=betas.csv fmt=csv

This will generate the following files:

    betas.csv      # betas, 50 rows of 1 column, csv format
    betas.csv.mtd  # metadata

The LinearRegDS.dml script generates statistics to standard output similar to the following.

	BEGIN LINEAR REGRESSION SCRIPT
	Reading X and Y...
	Calling the Direct Solver...
	Computing the statistics...
	AVG_TOT_Y,-2.160284487670675
	STDEV_TOT_Y,66.86434576808432
	AVG_RES_Y,-3.3127468704080085E-10
	STDEV_RES_Y,1.7231785003947183E-8
	DISPERSION,2.963950542926297E-16
	PLAIN_R2,1.0
	ADJUSTED_R2,1.0
	PLAIN_R2_NOBIAS,1.0
	ADJUSTED_R2_NOBIAS,1.0
	PLAIN_R2_VS_0,1.0
	ADJUSTED_R2_VS_0,1.0
	Writing the output matrix...
	END LINEAR REGRESSION SCRIPT

Now that we have our `betas.csv`, we can test our model with our second set of data.


<a name="test-model-on-second-sample" />

### Test Model on Second Sample

To test our model on the second sample, we can use the `GLM-predict.dml` script. This script can be used for both
prediction and scoring. Here, we're using it for scoring since we include the `Y` named argument. Our `betas.csv`
file is specified as the `B` named argument.  

    ./bin/systemml ./system-ml/scripts/algorithms/GLM-predict.dml -nvargs X=linRegData.test.data.csv Y=linRegData.test.labels.csv B=betas.csv fmt=csv

This generates the following statistics to standard output.

	LOGLHOOD_Z,,FALSE,NaN
	LOGLHOOD_Z_PVAL,,FALSE,NaN
	PEARSON_X2,,FALSE,1.895530994504798E-13
	PEARSON_X2_BY_DF,,FALSE,4.202951207327712E-16
	PEARSON_X2_PVAL,,FALSE,1.0
	DEVIANCE_G2,,FALSE,0.0
	DEVIANCE_G2_BY_DF,,FALSE,0.0
	DEVIANCE_G2_PVAL,,FALSE,1.0
	LOGLHOOD_Z,,TRUE,NaN
	LOGLHOOD_Z_PVAL,,TRUE,NaN
	PEARSON_X2,,TRUE,1.895530994504798E-13
	PEARSON_X2_BY_DF,,TRUE,4.202951207327712E-16
	PEARSON_X2_PVAL,,TRUE,1.0
	DEVIANCE_G2,,TRUE,0.0
	DEVIANCE_G2_BY_DF,,TRUE,0.0
	DEVIANCE_G2_PVAL,,TRUE,1.0
	AVG_TOT_Y,1,,1.0069397725436522
	STDEV_TOT_Y,1,,68.29092137526905
	AVG_RES_Y,1,,-4.1450397073455047E-10
	STDEV_RES_Y,1,,2.0519206226041048E-8
	PRED_STDEV_RES,1,TRUE,1.0
	PLAIN_R2,1,,1.0
	ADJUSTED_R2,1,,1.0
	PLAIN_R2_NOBIAS,1,,1.0
	ADJUSTED_R2_NOBIAS,1,,1.0


We see that the STDEV_RES_Y value of the testing phase is of similar magnitude
to the value obtained from the model training phase.

For convenience, we can encapsulate our DML invocations in a single script:

	#!/bin/bash
	
	./bin/systemml ./system-ml/scripts/datagen/genLinearRegressionData.dml -nvargs numSamples=1000 numFeatures=50 maxFeatureValue=5 maxWeight=5 addNoise=FALSE b=0 sparsity=0.7 output=linRegData.csv format=csv perc=0.5
	
	./bin/systemml ./system-ml/scripts/utils/sample.dml -nvargs X=linRegData.csv sv=perc.csv O=linRegDataParts ofmt=csv
	
	./bin/systemml ./system-ml/scripts/utils/splitXY.dml -nvargs X=linRegDataParts/1 y=51 OX=linRegData.train.data.csv OY=linRegData.train.labels.csv ofmt=csv
	
	./bin/systemml ./system-ml/scripts/utils/splitXY.dml -nvargs X=linRegDataParts/2 y=51 OX=linRegData.test.data.csv OY=linRegData.test.labels.csv ofmt=csv
	
	./bin/systemml ./system-ml/scripts/algorithms/LinearRegDS.dml -nvargs X=linRegData.train.data.csv Y=linRegData.train.labels.csv B=betas.csv fmt=csv
	
	./bin/systemml ./system-ml/scripts/algorithms/GLM-predict.dml -nvargs X=linRegData.test.data.csv Y=linRegData.test.labels.csv B=betas.csv fmt=csv


In this example, we've seen a small part of the capabilities of SystemML. For more detailed information,
please consult the SystemML Algorithm Reference and SystemML Language Reference.

