#-------------------------------------------------------------
#
# (C) Copyright IBM Corp. 2010, 2015
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#-------------------------------------------------------------

# JUnit test class: dml.test.integration.descriptivestats.CategoricalCategoricalTest.java
# command line invocation assuming $SS_HOME is set to the home of the R script
# Rscript $SS_HOME/ScaleScale.R $SS_HOME/in/ $SS_HOME/expected/
args <- commandArgs(TRUE)
options(digits=22)

library("Matrix")

X = readMM(paste(args[1], "X.mtx", sep=""))
Y = readMM(paste(args[1], "Y.mtx", sep=""))

# cor.test returns a list containing t-statistic, df, p-value, and R
cort = cor.test(X[,1], Y[,1]);

R = as.numeric(cort[4]);

write(R, paste(args[2], "PearsonR", sep=""));
