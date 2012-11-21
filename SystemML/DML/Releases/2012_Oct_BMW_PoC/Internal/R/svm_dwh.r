# on DML5, in bjr/bmw/data
# $ screen  => $ R => Ctrl-a Ctrl-d => $ logout => $ screen -x

library( Matrix);
library( e1071);
library( SparseM);

# read data frame and convert to sparse matrix w/ DTCs

# dim (dtcs): [1] 246,224,098         3
dtcs<-read.table( "svm_dtcs.mtx", sep=",", header=F, quote="\""
                 ,col.names = c("key", "dtc", "value")
                 ,colClasses=c("numeric","numeric","numeric"))

# ToDo: add 1 entry for each readout w/ no DTCs: dim(subset( roInfo, DTCcnt==0)): [1] 4,865,654      10
#       do it using an outerjoin at the source

# summary (mdtcs): 13,835,946 x 74,747 sparse Matrix of class "dgCMatrix", with 245,174,915 entries
mdtcs<-sparseMatrix( i= dtcs[,1]
                    ,j= dtcs[,2]
                    ,x= dtcs[,3]
                    )

# SVM

mysvm = svm( mdtcs[,1:74747-1], mdtcs[,74747], type="C-classification", kernel="linear", cost=1)
