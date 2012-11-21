names (x)              // "V1" "V2" "V3"
vinLevel=levels(x[,1]) // #the vin,time mapping
dtcLevel=levels(x[,2]) // #the dtc mapping


dtcs<-read.table( "c:\\BMWtmp\\vin_visit_dtc_vectors_vertical.del" , sep=",", header=F,
                  col.names=c("vinvis", "dtc", "dummy"),
                  colClasses=c("factor","factor","numeric"), quote="\"")
dim (dtcs)          // [1] 13378960        3
(dtcs[,1])[1:5]

fc <- file("mylist.txt")
mylist <- strsplit(readLines(fc), " ")
close(fc)

txlist = as (dtcs[,1:2], "transactions")

txlist = tapply(dtcs$dtc, dtcs$vinvis, function (x) x)
Error: cannot allocate vector of size 48 Kb
In addition: There were 22 warnings (use warnings() to see them)

txlist = by (dtcs, dtcs$vinvis, function(x) x$dtc)

// create list of transactions
c = tapply (x[,], dtcs[,1], sum);   // group by DTC sum (x[,3])

X<-sparseMatrix(i=as.integer(dtcs$vinvis),j=as.integer(dtcs$dtc),x=dtcs$dtc)
1096161 x 12326 sparse Matrix of class "dgCMatrix", with 13378960 entries 
dim (X)               //  1,407,052 readouts  12,326 features

// 
fc <- file("mylist.txt")
mylist <- strsplit(readLines(fc), " ")
close(fc)


dc = data.frame (day=seq(as.Date ("2007-01-08"), to=as.Date("2012-01-07"), by='days'))


// read out date distribution; "joining 2 data frames"

readOutAll = read.table( "c:\\BMWtmp\\readoutDateDistribution.del" , sep=",",
                         header=F, colClasses=c("Date","numeric"), col.names=c("day", "cntAll"), quote="\"")
readOutGoodUS = read.table( "c:\\BMWtmp\\readoutDateDistribution_good_vins_US.del" , sep=",",
                         header=F, colClasses=c("Date","numeric"), col.names=c("day", "cntGoodUs"), quote="\"")
m1 = merge (dc, readOutAll, all.x = TRUE)
m2 = merge (m1, readOutGoodUS, all.x = TRUE)
plot (m2$day, m2$cntAll, type = "p")
plot (m2$day, m2$cntGoodUs, type = "p")

--------------------------------------------------------------------------------

#prerequisites
#install.packages("randomForest");
library(randomForest);

#prepare input data
numRows <- 10
numCols <- 2
D <- matrix(runif(numRows*numCols), ncol=numCols) #independent vars (predictors) 
D[2,1] = NA  #just for test
D[is.na(D)] <- 0 
y <- matrix(sample(0:1, numRows, replace = T))  #dependent vars (response)
yf <- factor(y, labels = c("yes", "no"))                                                        
dfd = data.frame(D)
  
#estimate model             
model = randomForest( x=dfd, y=yf, ntree=50,
                      keep.forest=TRUE #required for later predict
        )               

#use model for new data
predict(model, dfd) #pass new Data
  
--------------------------------------------------------------------------------


# Replace NA with 0, as NA not permitted in predictors
d[,staPred:endPred][is.na(d[,staPred:endPred])] = FALSE;

# cast to factors
d$X0x1 = factor(d$X0x1)

# It cannot have NA, hence init w/ "car"
# Also change the type to factor
d$class[is.na(d$class)] = "car"
