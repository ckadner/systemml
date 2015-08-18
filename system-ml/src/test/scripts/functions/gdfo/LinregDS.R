#-------------------------------------------------------------
# IBM Confidential
# OCO Source Materials
# (C) Copyright IBM Corp. 2010, 2015
# The source code for this program is not published or
# otherwise divested of its trade secrets, irrespective of
# what has been deposited with the U.S. Copyright Office.
#-------------------------------------------------------------

args <- commandArgs(TRUE)
options(digits=22)
library("Matrix")

X = as.matrix(readMM(paste(args[1], "X.mtx", sep="")))
y = as.matrix(readMM(paste(args[1], "y.mtx", sep="")))
I = as.vector(matrix(1, ncol(X), 1));
intercept = as.integer(args[2])
lambda = as.double(args[3]);

if( intercept == 1 ){
   ones = matrix(1, nrow(X), 1); 
   X = cbind(X, ones);
   I = as.vector(matrix(1, ncol(X), 1));
}

A = t(X) %*% X + diag(I)*lambda;
b = t(X) %*% y;
beta = solve(A, b);

writeMM(as(beta,"CsparseMatrix"), paste(args[4], "B", sep=""))