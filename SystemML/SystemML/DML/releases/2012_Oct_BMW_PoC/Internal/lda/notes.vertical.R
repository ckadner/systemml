library(Matrix)
library(wordcloud)
library(reshape)
library(ggplot2)
library(topicmodels) #to check LDA vs GNMF
library(data.table) #for faster aggregations...
#library(lda)

#read base data
x<-read.table(gzfile("vertical.del.gz"),sep=",",header=F,quote="\"",colClasses=c("factor","character","numeric"))
x[,2]<-as.integer(x[,2])+1 #make desc 1-based
dim(x) #15Mil x 3
vinLevel<-levels(x[,1]) #the vin,visit,time mapping

dtcLevel<-read.table("dtc_descript_map.del",sep=",",header=F,quote="\"",colClass=c("integer","character"))[,2]
#dtcLevel<-levels(x[,2]) #the dtc mapping

#read dtc "dictionary"
#y<-read.table("dtc_entries.del",sep=",",header=F,quote="\"",colClasses=c("factor","factor","factor","factor"))
#colnames(y)<-c("year","model","ecu","dtc","desc")
#map unique dtc/model/year (263921) to desc (19569). It seems that different models/years/ecu share the same description but have different codes....

#create a sparse matrix for the vin or visits
x.visit<-factor(sapply(strsplit(as.character(x[,1]),"@",fixed=T),function(i) i[2]))
x.time<-strptime(sapply(strsplit(as.character(x[,1]),"@",fixed=T),function(i) i[3]),"%Y-%m-%dT%H:%M:%S")
y<-data.table(visit=as.integer(x.visit),dtc=as.integer(x[,2]),time=x.time-min(x.time),freq=x[,3])
setkeyv(y,c("visit","time"))
#find the 1st reading of a visitb
y.first<-y[,time==min(time),by="visit"]
foo<-y[y.first$V1,sum(freq),by="visit,dtc"]
X<-sparseMatrix(i=foo[,visit],j=foo[,dtc],x=foo[,V1])
colnames(X)<-dtcLevel
X.old<-X #keep a backup

#OR create a sparse matrix for the readouts
X<-sparseMatrix(i=as.integer(x[,1]),j=as.integer(x[,2]),x=x[,3])
dim(X) #1.4Mil x 12k
colnames(X)<-dtcLevel
X.old<-X #keep a backup

#compute the "covariance" matrix of dtc x dtc
#dtcCov<-crossprod(X)
#dim(dtcCov) #12k x 12k

#get the non-zero values out of the covariance matrix
#summary(dtcCov@x)
#boxplot(dtcCov@x)

#decode the j position out of the compressed column format dtcCov@p (for ease)
decodeMatrix <- function(A) {
  li<-0
  myj<-unlist(lapply(diff(A@p),function(y) {ret<-rep(li,y);li<<-li+1;ret}))
  list(i=A@i,j=myj,x=A@x)
}

#reorder dtc's by decreasing freq (we have that in the diagonal of the covariance matrix)
#dtcFreq<-diag(dtcCov)
#dtcFreq.dec<-sort.list(dtcFreq,dec=T)
#dtcCov.Freq.reorder<-dtcCov[dtcFreq.dec,dtcFreq.dec]
#image(dtcCov.Freq.reorder[1:300,1:300]) #plot the upper-left corner of the reorder matrix (not very enlightening)


#let's try reordering using an eigenvector-like approach
GNMF<-function(V,k=10,maxit=20) {
  W<-matrix(runif(nrow(V)*k),ncol=k)
  H<-matrix(runif(ncol(V)*k),nrow=k)
  for(it in 1:maxit) {
#    cat(".")
    Hn<-H * crossprod(W,V)/(crossprod(W) %*% H )
    Wn<-W * tcrossprod(V,H)/(W %*% tcrossprod(H))
    H<-as.matrix(Hn)
    W<-as.matrix(Wn)
  }
  list(W=W,H=H)
}


dtcFact<-GNMF(X,1,maxit=10)$H[1,]
dtcFact.dec<-sort.list(dtcFact,dec=T)
dtcCov.Fact.reorder<-dtcCov[dtcFact.dec,dtcFact.dec]
image(dtcCov.Fact.reorder[1:1000,1:1000]) #plot the upper-left corner of the reorder matrix (improved!)

#use LDA on a small sample
nTopic<-20
sa<-sample(1:nrow(X.old),0.1*nrow(X.old),rep=F)
#sa<-1:nrow(X.old)
X<-X.old[sa,]
X.foo<-decodeMatrix(X)
X.foo<-simple_triplet_matrix(X.foo$i+1,X.foo$j+1,X.foo$x)
system.time(X.lda<-LDA(X.foo,nTopic,control=list(verbose=1,var=list(tol=10^-4),em=list(tol=10^-4),alpha=0.01 )))
#system.time(X.lda<-LDA(X.foo,nTopic,method="Gibbs",control=list(verbose=1,iter=400,burnin=50,alpha=0.01)))
X.post<-posterior(X.lda)
dtcNMF<-list(W=X.post$topics,H=X.post$terms)


#do a "spectral-clustering" over some NMF factors
#nTopic<-10
#dtcNMF<-GNMF(X,nTopic,maxit=20)
#dtcKM<-kmeans(t(dtcNMF$H),nTopic)
#pairs(as.matrix(t(dtcNMF$H)),col=dtcKM$topic)

#assign readouts to the most probable topic
read.assign<-apply(dtcNMF$W,1,which.max)
read.assign.total<-tapply(read.assign,read.assign,length)
read.assign.order<-sort.list(read.assign.total,dec=T)

#ranks readings based on how well they fit the topics
read.rank<-apply(dtcNMF$W,1,max)
read.rank.order<-sort.list(read.rank,dec=F)
vinLevel[read.rank.order[1:20]] #get the top-20 readings that don't seem to match the topics

#reorder NMF$W/H from the biggest topic to the smaller
#dtcNMF$H<-dtcNMF$H[read.assign.order,]
#dtcNMF$W<-dtcNMF$W[,read.assign.order]
#read.assign<-apply(dtcNMF$W,1,which.max)

#find the 10-most important DTCs per topic
dtcImp<-sapply(1:nTopic,function(i) sort.list(dtcNMF$H[i,],dec=T)[1:8])
dtcImp.W<-sapply(1:nTopic,function(i) sort(dtcNMF$H[i,],dec=T)[1:8])
rownames(dtcImp.W)<-NULL
dtcImp.Freq<-sapply(1:nTopic,function(i) colSums( X[,dtcImp[,i]] )) #global frequency
dtcImp.Spec<-sapply(1:nTopic,function(i) colSums(X[read.assign==i,dtcImp[,i]])/colSums( X[,dtcImp[,i]] )) #topic specificity
topic.names<-paste("topic",1:nTopic,sep="")
topic.names<-paste(paste(topic.names,round(100*read.assign.total/nrow(X),2),sep="-"),"%",sep="")
colnames(dtcImp)<-topic.names
colnames(dtcImp.W)<-topic.names
colnames(dtcImp.Freq)<-topic.names
colnames(dtcImp.Spec)<-topic.names
#par(mfrow=c(3,3))
#for(i in 1:nTopic) wordcloud(dtcImp[,i],dtcImp.W[,i],scale=c(.5,4),random.order=F,rot.per=0)

#do a better job using ggplot()
mlt1<-melt(dtcImp)
colnames(mlt1)<-c("pos","topic","DTC")
mlt2<-melt(dtcImp.Freq)
colnames(mlt2)<-c("pos","topic","Freq")
mlt3<-melt(dtcImp.Spec)
colnames(mlt3)<-c("pos","topic","Spec")
dtcImp.mlt<-merge(merge(mlt1,mlt2),mlt3)
dtcImp.mlt$topic<-factor(dtcImp.mlt$topic,level=topic.names[read.assign.order],order=T)
p<-ggplot(dtcImp.mlt[dtcImp.mlt$topic %in% levels(dtcImp.mlt$topic)[1:5],],
       aes(y=pos,x=1.2,label=paste(DTC,substr(dtcLevel[DTC],1,85),sep="-"),
           #label=dtcLevel[DTC],
           size=1,xmin=0,xmax=5,ymin=0.75,ymax=5.25))+
  geom_text(size=2.5,hjust=0,col="blue")+
  facet_wrap(~topic,ncol=1)+theme_bw()+scale_y_reverse()+
  opts(legend.position="none",axis.ticks=theme_blank(),axis.text.y=theme_blank(),panel.grid.minor=theme_blank(),panel.grid.major=theme_blank(),
     axis.text.x=theme_blank())+labs(x="",y="")+geom_vline(xintercept=c(0,0.5,1),col="black",linetype=2)+
  geom_point(aes(y=pos,x=Spec,size=log(1+Freq/(max(Freq)-min(Freq)))),shape=1,col="red")
print(p)
#ggplot(dtcImp.mlt,aes(y=pos,x=Spec,label=dtcLevel[DTC],col=log(1+Weight/(max(Weight)-min(Weight))),size=3,xmin=-0.1,xmax=1.15))+geom_text()+facet_wrap(~topic,ncol=5)+theme_bw()+scale_y_reverse()+opts(legend.position="none",axis.ticks=theme_blank(),axis.text.y=theme_blank(),axis.text.x=theme_text())+labs(x="",y="")+scale_color_gradientn(colours=topo.colors(5))

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
