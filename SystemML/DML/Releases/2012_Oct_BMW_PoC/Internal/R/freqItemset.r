// Frequent Itemset mining (ECLAT algorithm)

library(arules)

// list of transactions with each transaction a list of DTCS

txdtcs = read.transactions (file="c:\\BMWtmp\\vin_visit_dtc_vectors_vertical.del", format="single", sep=",", cols=c(1,2))
> summary (txdtcs)
#   transactions as itemMatrix in sparse format with
#    1096161 rows (elements/itemsets/transactions) and
#    12326 columns (items) and a density of 0.0009902067 
#   
#   most frequent items:
#     0x9312   0x9CAD   0xA0AE   0x9CA7   0x9CDE  (Other) 
#     168087   158900   158038   157946   157880 12578109 
#   
#   element (itemset/transaction) length distribution:
#   sizes
#       1     2     3     4     5     6     7     8     9    10    11    12    13 
#   61761 69701 69710 66799 60967 55925 52226 56766 57025 51822 42336 47009 36298 
#      14    15    16    17    18    19    20    21    22    23    24    25    26 
#   41717 32182 27941 22419 20464 21233 19298 15686 14060 13426 12388 11659 11517 
#      27    28    29    30    31    32    33    34    35    36    37    38    39 
#   11677 10837  9556  8231  7233  6210  5550  5116  3994  3151  2928  2840  2401 
#      40    41    42    43    44    45    46    47    48    49    50    51    52 
#    2067  1658  1544  1330  1209  1133  1057   929   829   796   763   660   626 
#      53    54    55    56    57    58    59    60    61    62    63    64    65 
#     588   537   510   489   468   412   334   377   339   314   300   289   257 
#      66    67    68    69    70    71    72    73    74    75    76    77    78 
#     222   221   218   208   184   177   154   167   138   149   118   109   114 
#      79    80    81    82    83    84    85    86    87    88    89    90    91 
#     107   103   101    90    82    72    74    54    50    73    68    48    53 
#      92    93    94    95    96    97    98    99   100   101   102   103   104 
#      51    39    48    46    38    45    37    34    25    35    33    21    30 
#     105   106   107   108   109   110   111   112   113   114   115   116   117 
#      22    23    22    13    27    17    15    20    11    11    11    12    10 
#     118   119   120   121   122   123   124   125   126   127   128   129   130 
#      11     7    13     7     9    15    12     8     9    12    13    11     7 
#     131   132   133   134   135   136   137   138   139   140   141   142   143 
#       7    10    10     3     5     7     4     9     2     3     6     6     2 
#     144   145   146   147   148   149   150   151   152   153   154   155   156 
#       6     7     2     3     7    11     6     3     4     6     5     1     3 
#     157   158   159   160   161   162   163   164   165   166   167   168   169 
#       4     6     4     2     3     4     3     1     3     1     2     2     3 
#     170   171   172   173   174   175   176   177   178   179   180   181   182 
#       2     3     3     4     1     3     5     1     3     1     2     1     2 
#     183   184   185   186   187   188   189   191   192   193   194   195   197 
#       2     3     1     1     4     2     1     4     1     1     1     2     2 
#     198   199   201   202   204   206   207   208   210   212   215   216   217 
#       1     1     2     1     2     2     1     1     1     1     2     2     2 
#     218   220   224   225   227   228   230   232   233   235   238   239   241 
#       1     1     2     1     1     2     1     1     1     1     2     1     1 
#     243   244   245   253   254   265   267   270   271   272   273   278   279 
#       1     1     2     2     1     1     1     1     2     1     3     1     1 
#     287   288   292   293   305   314   327   339   347   364   374   395   401 
#       2     2     1     1     1     1     1     1     1     1     1     1     1 
#     422   514   610 
#       1     1     1 
#   
#      Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#      1.00    5.00    9.00   12.21   16.00  610.00 
#   
#   includes extended item information - examples:
#     labels
#   1    0x0
#   2    0x1
#   3   0x10
#   
#   includes extended transaction information - examples:
#                                      transactionID
#   1 0000171dd017cdeba54892948dcd901e@1314172670922
#   2 0000171dd017cdeba54892948dcd901e@1320915403866
#   3 0000171dd017cdeba54892948dcd901e@1323853087714
#   


// itemset mining; nothing found for support = 0.1
itemsets = eclat (txdtcs, parameter = list(supp = 0.1, maxlen = 5, tidLists=TRUE))

# save tidLists
save (itemsets)

WRITE (itemsets, file="c:\\BMWtmp\\itemsets119_01_5.del", sep= " ")

> itemsets
# set of 119 itemsets 

> summary (itemsets)
#  set of 119 itemsets
#  
#  most frequent items:
#   0x9312  0x9CA7  0x9CAD  0x9CDE  0xA0AE (Other) 
#       57      57      57      57      57     114 
#  
#  element (itemset/transaction) length distribution:sizes
#   1  2  3  4  5 
#   7 21 35 35 21 
#  
#     Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#    1.000   3.000   3.000   3.353   4.000   5.000 
#  
#  summary of quality measures:
#      support      
#   Min.   :0.1006  
#   1st Qu.:0.1015  
#   Median :0.1430  
#   Mean   :0.1233  
#   3rd Qu.:0.1439  
#   Max.   :0.1533  
#  
#  includes transaction ID lists: TRUE 
#  
#  mining info:
#     data ntransactions support
#   txdtcs       1096161     0.1

> inspect(itemsets)
# ... shows 119 itemsets and support

> inspect(sort(itemsets)[1:5])
# top 5 itemsets by support
  items      support
1 {0x9312} 0.1533415
2 {0x9CAD} 0.1449605
3 {0xA0AE} 0.1441741
4 {0x9CA7} 0.1440901
5 {0x9312,          
   0xA0AE} 0.1440765

## Print the 5 itemsets with the highest support as a data.frame.
as(sort(itemsets)[1:5], "data.frame")

## Get the itemsets as a list
as(items(itemsets.top5), "list")
 
## Inspect visually.
image(tidLists(itemsets))
 
## Get dimensions of the tidLists.
dim(tidLists(itemsets))
 
## Get the itemsets as a binary matrix
as(items(itemsets.top5), "matrix")

## Coerce tidLists to list.
as(tidLists(itemsets), "list")

# inspect itemsets
inspect(itemsets[1])

# summary (tidLists(itemsets))
summary (tidLists(itemsets))
#   tidLists in sparse format with
#    119 items/itemsets (rows) and
#    1096161 transactions (columns)
#   
#   most frequent transactions:
#        113      114      115      117      110  (Other) 
#     168087   158900   158038   157946   157931 15285664 

tidLists = as(tidLists(itemsets),"list")

> size(items(itemsets))
  [1] 5 5 5 5 5 5 4 4 4 4 5 5 5 4 4 4 5 4 4 4 3 3 3 3 3 5 5 5 4 4 4 5 4 4 4 3 3 3
 [39] 3 5 4 4 4 3 3 3 4 3 3 3 2 2 2 2 2 2 5 5 5 4 4 4 5 4 4 4 3 3 3 3 5 4 4 4 3 3
 [77] 3 4 3 3 3 2 2 2 2 2 5 4 4 4 3 3 3 4 3 3 3 2 2 2 2 4 3 3 3 2 2 2 3 2 2 2 1 1
[115] 1 1 1 1 1

> size(tidLists(itemsets))
  [1] 110354 110385 110344 111219 111250 111260 111263 111294 111253 110388 110314
 [12] 110346 110355 110358 110390 110349 111220 111223 111256 111265 111268 111302
 [23] 111259 110393 111297 110367 110385 110395 110413 110429 110401 111261 111277
 [34] 111295 111305 111323 111339 111312 110447 110355 110375 110390 110399 110421
 [45] 110434 110410 111265 111285 111301 111310 111334 111347 111327 110456 111358
 [56] 111305 156767 156798 156824 156827 156858 156801 157713 157716 157751 157773
 [67] 157776 157811 157754 156861 156779 156782 156814 156840 156843 156876 156817
 [78] 157728 157731 157772 157791 157796 157849 157775 156879 157814 156811 156833
 [89] 156845 156871 156895 156905 156869 157761 157839 157799 157821 157901 157859
[100] 157880 156931 156826 156852 156861 156887 156921 156936 156890 157776 157931
[111] 157820 157839 168087 158900 158038 157399 157946 157880 111415

istx = as(tidLists(itemsets), "data.frame")

# analysis of incidence matrix
m = as(tidLists(itemsets), "matrix")
m[,1]
cs=colSums(m)
cs[cs>0]
> length(cs[cs>0])
[1] 169705
vcs = cs[cs>0]
cs[cs==119][1:10]
> cs[cs==119][1:10]
0001b28f6365766d77722ba02775fb5b@1319475041937 0002971b202ef24df4702cd77214a850@1310743559718 
                                           119                                            119 
0002f8804db02a9b390cf3acf38059b2@1319466675295 0003eb024bca46964fd91b9011939214@1323173503294 
                                           119                                            119 
000400aed19a7157cc6e82063e330b58@1321609402898 000488d64795bfe1bd0c528a00ed0cb9@1322468905937 
                                           119                                            119 
0004c049ee90e5de879009c131f3b55d@1323169949140 0004d6199685543d91e24eceb5c46427@1311352566401 
                                           119                                            119 
0004f1de8ac91ffe9acb51e383aed9c4@1305977224077 0005e758d53628da745651eb523de0ec@1314262683814 
                                           119                                            119

0001b28f6365766d77722ba02775fb5b@1319475041937 119
0002971b202ef24df4702cd77214a850@1310743559718 119
0002f8804db02a9b390cf3acf38059b2@1319466675295 119
0003eb024bca46964fd91b9011939214@1323173503294 119
000400aed19a7157cc6e82063e330b58@1321609402898 119
000488d64795bfe1bd0c528a00ed0cb9@1322468905937 119
0004c049ee90e5de879009c131f3b55d@1323169949140 119
0004d6199685543d91e24eceb5c46427@1311352566401 119
0004f1de8ac91ffe9acb51e383aed9c4@1305977224077 119
0005e758d53628da745651eb523de0ec@1314262683814 119




# Alternative reading of vertical
dtcs = read.transactions (file="c:\\BMWtmp\\vin_visit_dtc_vectors_vertical.del", format="single", sep=",", cols=c(1,2))
length (dtcs)
[1] 1096161
read.transactions (file="c:\\BMWtmp\\vin_visit_dtc_vectors_horizontal2.del", format="basket", sep="\nb", cols=c(1,2))



################################################################################

# VINs and count of matching sequence rules

v<-read.table( "c:\\BMWtmp\\toni\\seqrules_apply_agg.del" , sep=",", header=F, colClasses=c("factor","numeric"), quote="\"")

# nbr of VINs w/ matching rule(s)
dim(v)
[1] 25973     2

# Distribution of nbr of matching rules
hist(v$V2, xlab = "Nbr of Matching Rules", main = paste("Histogram of", "Nbr of Matching Rules"), breaks=100)

# Top 10 VINs based on nbr of matching rules
(v[order(v$V2,v$V1, decreasing=TRUE), ])[1:10,]

VIN                              Nbr Matching Rules
0a360d16e03bce9de96ea88680514c1d 477
9dedc1996c073e77cac96d266a8b8326 476
dcbf947b422062553e9502eb39add903 470
f51e4ffbdd75c116d314fbe74d058d4b 466
84ad4fb423b841b04011484a8a9a62fe 466
799ed3a640edb757f8532218b767e853 466
75dfb684b2eb0038a990171b38216e18 466
5ee8e9ef141b0c0eb7929623c1088821 466
48e11385a0e2fc167e6c7a8630e54614 466
2afe0b9409d029d7e154f8b3ce111a8f 466

# summary of nbr of matching rules
summary(v$V2)
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
   1.00    3.00   13.00   31.86   26.00  477.00



