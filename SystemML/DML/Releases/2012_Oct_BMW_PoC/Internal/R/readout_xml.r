library( Matrix);
library( e1071);
library( SparseM);

setwd ("c:\\BMWtmp") 

#######################
# read in readout info
#######################

# dim( roInfo): [1] 1,654,445      11
roInfo<-read.table( "vin_visit_readout_readout_info.del" , sep=",", header=F, quote="\""
                   ,row.names = 1
                   ,col.names  = c("key", "fgnr7", "visitId", "vorgangAnlageZeitpunkt", "modelYear",
                                   "description", "fzgtestkmStand", "class", "ldate", "DTCcnt", "DTClist",
                                   "fzgauftrag")
                   ,colClasses = c("factor", "factor", "numeric", "factor", "factor",
                                 "factor", "numeric", "factor", "factor", "numeric", "character",
                                 "character"));

# there are 247,392 readouts w/ DTCcnt=0. That is, we have 1,407,053 readouts with DTCs
dim(subset( roInfo, DTCcnt==0))
# We have 975,192 cars
length( unique( roInfo$fgnr7))
# 2,892 of these cars are lemons.
length( unique( subset( roInfo, class=="lemon")$fgnr7))

# LemonReadOutInfo
lroInfo = subset( roInfo, class=="lemon")
# 10,233 readouts are for lemons: [1] 10233    11
dim(lroInfo)

# write lemon readouts
tmp = lroInfo[ order( lroInfo$fgnr7, +lroInfo$visitId, lroInfo$vorgangAnlageZeitpunkt, +lroInfo$fzgtestkmStand),]
write.csv (lroInfo, file="lemonCarReadoutInfowDTCs.csv")

# Nbr of visits for car: lroInfo$Viscntname
aggregate( lroInfo$visitId, list( lroInfo$fgnr7), function(s) length(unique(s)))


######################
# Readout dtcs
######################

# dim: 15,120,096        3
dtcs<-read.table( "vin_visit_readout_readOut_dtcs_vertical.del.gz", sep=",", header=F, quote="\""
                 ,col.names = c("key", "dtc", "value")
                 ,colClasses=c("factor","factor","numeric"))

# add entries for 0 rows
tmp1 = rownames(subset( roInfo, DTCcnt==0))
tmp = data.frame( tmp1
                 ,rep( dtcs[1,2], length( tmp1))
                 ,rep( 0, length( tmp1))
                 )
colnames( tmp) = c("key", "dtc", "value")
strdtcs = rbind( dtcs, tmp)

# create sparse matrx w/ DTCs
# summary( mdtcs): # 1,407,053 x 12,326 sparse Matrix of class "dgCMatrix", with 15,120,096 entries.
# Use dims to set it to 1,654,445 x 12,326 to counter for 247,392 empty rows.
# dim (mdtcs): [1] 1654445   12326
mdtcs<-sparseMatrix( i=as.integer( dtcs[,1])
                    ,j=as.integer( dtcs[,2])
                    ,x=dtcs[,3]
                    ,dimnames = list( levels( dtcs[,1]), levels( dtcs[,2])))

#########
# SVM
#########

svm( mdtcs, type="C-classification", kernel="linear", cost=1)
