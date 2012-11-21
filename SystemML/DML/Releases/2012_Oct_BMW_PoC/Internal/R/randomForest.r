#
# R script to run randomForest on BMW dtc data (horizontal representation)
#

# 1. vin - 1st - 1st
# 2. vin unionall
#       2.a 1stROSumVis
#       2.b BinAggRoSumVis
# 
setwd ("c:\\BMWtmp");

library(randomForest);

# load and prepare input data
#    names( d), ls( d), summary( d), object.size( d), typeof (d$vin), typeof (d$class)
#    str (d[,1:9])

# get col count by reading only 1 row
d<-read.table( "vin_visit_readout_dtc_vectors_horizontal_head.del" , sep=",", header=F, quote="\"" ,nrows = 1);
# useful column lists

xColNames = c("vin", "visId", "rdate", "myear", "mdesc", "mileage", "class", "ldate", "options");

# We have 12,335 cols. Substract the non-dtc columns for the range of independent vars (predictors)
# i.e. d[,starPred:endPred]
staPred = length (xColNames) + 1;
endPred = length(names(d));

allColclasses = c(rep (NA, length(xColNames)), rep("factor", endPred-staPred))

# read in all the data
rm(d);
d<-read.table( "vin_visit_readout_dtc_vectors_horizontal_lemon_dtc.del" , sep=",", header=T, quote="\"", colClasses = allColclasses );


# d$class is our dependent variable (response).
# model building
c <- factor(d$class) 
model = randomForest(  x = d[,staPred:endPred], y = c
                      ,ntree=50,
                      ,keep.forest = TRUE , d.trace=TRUE
        )               

# plot
# plot (model)

# save and load 

save (model, file="BMWLemon.rda", ascii=TRUE)
# load ("BMWLemon.rda")

# prediction
# p = predict(model, d[,staPred:endPred])
