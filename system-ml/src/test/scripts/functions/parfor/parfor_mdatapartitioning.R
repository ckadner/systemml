#-------------------------------------------------------------
# IBM Confidential
# OCO Source Materials
# (C) Copyright IBM Corp. 2010, 2013
# The source code for this program is not published or
# otherwise divested of its trade secrets, irrespective of
# what has been deposited with the U.S. Copyright Office.
#-------------------------------------------------------------

args <- commandArgs(TRUE)
options(digits=22)

library("Matrix")

V1 <- readMM(paste(args[1], "V.mtx", sep=""))
V <- as.matrix(V1);
n <- ncol(V); 

R1 <- array(0,dim=c(1,n))
R2 <- array(0,dim=c(1,n))

for( i in 1:n )
{
   X <- V[ ,i];                 
   R1[1,i] <- sum(X);
}   

if( args[3]==1 )
{  
  for( i in 1:n )
  {
     X1 <- V[i,]; 
     X2 <- V[i,];                 
     R2[1,i] <- R1[1,i] + sum(X1)+sum(X2);
  }   
} else {
  for( i in 1:n )
  {
     X1 <- V[i,]; 
     X2 <- V[,i];                 
     R2[1,i] <- R1[1,i] + sum(X1)+sum(X2);
  }  
}

writeMM(as(R2, "CsparseMatrix"), paste(args[2], "Rout", sep="")); 