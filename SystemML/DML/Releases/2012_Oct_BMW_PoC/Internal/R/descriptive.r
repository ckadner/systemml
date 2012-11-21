setwd ("c:\\BMWtmp")

dtcs<-read.table( "c:\\BMWtmp\\vin_visit_readout_dtc_vectors_vertical.del" , sep=",", header=F, quote="\""
              ,col.names = c("key",    "vin",    "visitId" ,"readoutDate" ,"mileage" ,"modelYear" ,"description" ,"car_options" ,"class"  ,"ldate"     ,"dtc"    ,"value"  )
              ,colClasses= c("factor" ,"factor" ,"factor"  ,"Date"        ,"factor"  ,"factor"    ,"character"   ,"factor"      ,"factor" ,"character" ,"factor" ,"integer")
              )

//
// analysis of the *vertical* representation of the file
//

class(dtcs)            // "data.frame"
head(dtcs)             // 
names (dtcs)
 [1] "key"         "vin"         "visitId"     "readoutDate" "mileage"     "modelYear"   "description"
 [8] "car_options" "class"       "ldate"       "dtc"         "value" 
object.size(dtcs)      // 1325708304 bytes
dtcs[1:5,]
dtcs$description[1:5]  // [1] "328xi" "328xi" "328xi" "328xi" "328xi"
dim(dtcs)              // [1] 15120087       12
nrow (dtcs)            // [1] 15120087
ncol(dtcs)             // [1] 12


//
// summary of vertical representation
//
  
summary (dtcs)  // summary (dtcs$dtc)
                                                                     key          
 9f14d5b1b6b4c680b265fa44586519fb@1297412214952@2011-02-21T08:21:30.124:     328  
 d751b7f24f8e18d65c9bd10c83228dcd@1294738217109@2011-01-24T14:50:55.789:     308  
 da3f31d217676e55602d7458f533fe9d@1297262697764@2011-07-21T14:05:23.608:     301  
 da3f31d217676e55602d7458f533fe9d@1297262697764@2011-07-22T08:18:12.624:     298  
 419bb0871c73fd9f149f7af7939454c5@1294755887374@2011-02-03T08:47:08.234:     291  
 8150ec6c7249ed2da020c6ef0444e47a@1308227480798@2011-06-16T13:17:06.532:     289  
 (Other)                                                               :15118272  
                               vin                    visitId          readoutDate            mileage        
 d869e8fe4f14e3e418e01da68dda1f3b:    4134   1292458049939:    4134   Min.   :2010-04-30   7      :  545425  
 338be48683d7db0659325a82973f14b9:    2116   1294928350140:    2116   1st Qu.:2011-04-19   8      :  489045  
 419bb0871c73fd9f149f7af7939454c5:    1886   1294755887374:    1772   Median :2011-07-21   6      :  435220  
 02dffa9c2693a38d4d7a8b7342d610ea:    1644   1307086507293:    1584   Mean   :2011-07-15   9      :  430560  
 d133aa2646a5cfe202058df1c9ebc1a4:    1592   1296119941984:    1493   3rd Qu.:2011-10-18   5      :  316271  
 04db7e909f6ea1fbac4794904dd485ae:    1493   1310569705347:    1488   Max.   :2011-12-31   10     :  305690  
 (Other)                         :15107222   (Other)      :15107500                        (Other):12597876  
   modelYear       description        car_options   class             ldate                dtc               value  
 2011   :3544333   Length:15120087    :15120087        :15049573   Length:15120087    0x9312 :  170356   Min.   :1  
 2007   :2013834   Class :character               lemon:   70514   Class :character   0x9CAD :  159980   1st Qu.:1  
 2006   :1707962   Mode  :character                                Mode  :character   0xA0AE :  158898   Median :1  
 2005   :1413684                                                                      0x9CA7 :  158813   Mean   :1  
 2008   :1222576                                                                      0x9CDE :  158747   3rd Qu.:1  
 2010   :1203417                                                                      0xA6E7 :  158347   Max.   :1  
 (Other):4014281                                                                      (Other):14154946


//
// Column-level analysis
//

length( unique( dtcs$key))                  // [1] 1,407,052 keys (i.e. readouts)
length( unique( dtcs$vin))                  // [1] 908,228 VINs
length( unique( sapply(                     // [1] 908,228 VINs
   levels(dtcs$key),
   function(i) strsplit(i,"@")[[1]][1] )))
length( unique( dtcs$visitId))              // [1] 1,095,830 Visits
nrow( tapply( dtcs$value, dtcs$dtc, sum)    // [1] 12,326 distinct DTCs
summary( tapply( dtcs$value, dtcs$dtc, sum) // [1]  Min.: 1;  1st Qu.: 5;  Median: 32;  Mean 3rd Qu.: 1227;  Max.: 170,400

// Visualize

hist (x, 10)
plot (x)


//
// Matrix w/ Feature Vectors
//
        
library (Matrix)

m = sparseMatrix( i = as.integer( dtcs$key), j = rep( 1, length( dtcs$key)), x = as.integer( dtcs$mileage))

X<-sparseMatrix(i=as.integer(x[,1]),j=as.integer(x[,2]),x=x[,3])
dim (X)               //  1,407,052 readouts  12,326 features




