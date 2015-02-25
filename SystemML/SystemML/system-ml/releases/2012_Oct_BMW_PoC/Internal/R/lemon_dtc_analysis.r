setwd ("c:\\BMWtmp") 


################################################################################
# Analyze file LemonList_PseudoVIN_V01_MAY2012_... FILE (lemon list)
################################################################################

lemons<-read.table( "LemonList_PseudoVin_V01_May2012_20120618_jpr.csv" , sep=",", colClasses= c("character", "factor"), header=T, quote="")

# convert date format
lemons[,1] = unlist (lapply (lemons[,1], function (s) format( strptime( s, "%m/%d/%Y"), "%Y-%m-%d")))

#
# Lemon VINs
#
length (lemons$VIN)
# [1] 8806

#
# Lemon Data Distribution
#
x = tapply( lemons$REPARATURDATUM_Min, as.Date(lemons$REPARATURDATUM_Min), length)
dx = data.frame(as.Date(names(x)), x[])
colnames(dx) <- c ("day", "count")
summary(dx$count)
#   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#   1.00    6.00   11.00   11.22   16.00   43.00 
dtmp  = data.frame (day=seq(as.Date (min(dx$day)), to=as.Date(max(dx$day)), by='days'))
dm = merge (dtmp, dx, all.x = TRUE)
plot (dm$day, dm$count, type = "p")


################################################################################
# Analyze DTC codes and meta data that we have for lemons.
################################################################################
 
# load and prepare input data
#    names( d), ls( d), summary( d), object.size( d), typeof (d$vin), typeof (d$class)
#    str (d[,1:9])

# get col count by reading only 1 row
hdr<-read.table( "vin_visit_readout_dtc_vectors_horizontal_head.del" , sep=",", header=T, quote="\"" ,nrows = 0);
# useful column lists

xColNames = c("vin", "visId", "rdate", "myear", "mdesc", "mileage", "class", "ldate", "options");

# We have 12,335 cols. Substract the non-dtc columns for the range of independent vars (predictors)
# i.e. d[,starPred:endPred]
staPred = length (xColNames) + 1;
endPred = length(names(hdr));
allColclasses = c(rep (NA, length(xColNames)), rep("logical", endPred-staPred+1))

# read in all the data
ldtcs<-read.table( "vin_visit_readout_dtc_vectors_horizontal_lemon_dtc.del" , sep=",", header=F, quote="\"", col.names = names(hdr), colClasses = allColclasses );


#
# ReadOut/VINs
#
# [1] 10233 readouts for lemons
length (ldtcs$vin)
# [1] 2892 cars
length (unique (ldtcs$vin))
# distribution of readouts for lemons cars
xvin = tapply (ldtcs$vin, ldtcs$vin, length)

plot (sort (xvin, decreasing = TRUE),
      type ="l",
      main="Frequency of ReadOuts for Lemon Cars",
      xlab="Lemon Cars",
      ylab="ReadOut Count")

# sort VIN data frame
dvin = data.frame(names(xvin), xvin[])
colnames(dvin)[1] = "VIN"
colnames(dvin)[2] = "ReadOutCount"
dvin[order(-dvin$ReadOutCount),]

# Count of VINS for ReadoutCount
yvin = tapply (dvin$ReadOutCount, dvin$ReadOutCount, length)
  1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24 
953 646 380 230 176  98 103  72  52  39  23  23  17  12  11  15   3  10   5   2   4   3   2   1 
 25  26  27  30  31  32  33  34  38  42  53 
  2   1   1   1   1   1   1   1   1   1   1 

text (length(xvin)*.55, range(0,xvin)[2]*.65, cex=.6, pos=4, 
      "2,892 lemons w/ diagnostic files. \n953 w/ 1 ReadOut(s). \n646 w/ 2 ReadOuts. \n380 w/ 3 Readouts. \n919 w/ > 3 Readouts. \nConclusion: We can only detect 919 lemons \nfrom the diagnostic readouts.")

#
#
#
# add DTCs count
# apply works better than rowSums; ldtcs$cntDTCS = rowSums( ldtcs[, staPred:endPred]*1)
ldtcs$cntDTCS = sapply( ldtcs[ staPred:endPred]*1, sum)
xColNames[length(xColNames)+1]="cntDTCS"
# xColIdxs
xCIdxs = match( xColNames, names(ldtcs))
# lemon car data frame
lcar = ldtcs[, xCIdxs]
lcar$rdate = as.Date (lcar$rdate)

# sorting and write CSV file with car information for Excel 
head( lcar[ order( lcar$vin, +lcar$visId, +lcar$rdate) ,])
slcar = lcar[ order( lcar$vin, +lcar$visId, +lcar$rdate, +mileage),]
write.csv (slcar, file="lemonCarReadoutInfo.csv")

********************************************************************************
R> vec <- 1:10
R> DF <- data.frame(start=c(1,3,5,7), end=c(2,6,7,9))
R> DF$newcol <- apply(DF,1,function(row) mean(vec[ row[1] : row[2] ] ))
R> DF
  start end newcol
1     1   2    1.5
2     3   6    4.5
3     5   7    6.0
4     7   9    8.0



