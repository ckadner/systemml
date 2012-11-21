library(Matrix)

#read base data
x<-read.table(gzfile("vertical.del.gz"),sep=",",header=F,quote="\"",colClasses=c("factor","factor","numeric"))
dim(x) #15Mil x 3
vinLevel<-levels(x[,1]) #the vin,time mapping
dtcLevel<-levels(x[,2]) #the dtc mapping

#create a sparse matrix
X<-sparseMatrix(i=as.integer(x[,1]),j=as.integer(x[,2]),x=x[,3])
dim(X) #1.4Mil x 12k

#compute the "covariance" matrix of dtc x dtc
dtcCov<-crossprod(X)
dim(dtcCov) #12k x 12k

#get the non-zero values out of the covariance matrix
summary(dtcCov@x)
boxplot(dtcCov@x)

#decode the j position out of the compressed column format dtcCov@p (for ease)
li<-0;dtcCov.j<-unlist(lapply(diff(dtcCov@p),function(y) {ret<-rep(li,y);li<<-li+1;ret}))

#reorder dtc's by decreasing freq (we have that in the diagonal of the covariance matrix)
dtcFreq<-diag(dtcCov)
dtcFreq.dec<-sort.list(dtcFreq,dec=T)
dtcCov.Freq.reorder<-dtcCov[dtcFreq.dec,dtcFreq.dec]
image(dtcCov.Freq.reorder[1:300,1:300]) #plot the upper-left corner of the reorder matrix (not very enlightening)


#let's try reordering using an eigenvector-like approach
GNMF<-function(V,k=10,maxit=20) {
  W<-matrix(runif(nrow(V)*k),ncol=k)
  H<-matrix(runif(ncol(V)*k),nrow=k)
  for(it in 1:maxit) {
    cat(".")
    Hn<-H * (t(W) %*% V)/(crossprod(W) %*% H )
    Wn<-W * (V %*% t(H))/(W %*% tcrossprod(H))
    H<-Hn
    W<-Wn
  }
  list(W=W,H=H)
}

dtcFact<-GNMF(dtcCov,1,maxit=25)$W[,1]
dtcFact.dec<-sort.list(dtcFact,dec=T)
dtcCov.Fact.reorder<-dtcCov[dtcFact.dec,dtcFact.dec]
image(dtcCov.Fact.reorder[1:300,1:300]) #plot the upper-left corner of the reorder matrix (improved!)


#do a "spectral-clustering" over some NMF factors
dtcNMF<-GNMF(dtcCov.Fact.reorder,5,maxit=20)
dtcKM<-kmeans(dtcNMF$W,5)
pairs(as.matrix(dtcNMF$W),col=dtcKM$cluster)

#use to get an approximate low-rank decomposition of sparse matrix A (using random projections)
stochasticSVD <- function(A, k, p=10) {
  n = dim(A)[1]
  m = dim(A)[2]
  # random projection of A    
  Y = (A %*% matrix(rnorm((k+p) * m), ncol=k+p))
  # the left part of the decomposition works for A (approximately)
  Q = qr.Q(qr(Y))
  # taking that off gives us something small to decompose
  B = t(Q) %*% A
  # decomposing B gives us singular values and right vectors for A  
  s = svd(B)
  U = Q %*% s$u
  # and then we can put it all together for a complete result
  return (list(u=U, v=s$v, d=s$d))
}
