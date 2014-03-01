# Start from fresh
hadoop fs -rmr ./data

# Generate data in ./data
hadoop jar SystemML.jar -f genData.dml

# Categorical.dml
hadoop jar SystemML.jar -f DMLScripts/descriptivestats/Categorical.dml -args '"./data/C/in/vector"' 10000 '"./data/C/out/Nc"' '"./data/C/out/R"' '"./data/C/out/Pc"' '".data/C/out/C"' '"./data/C/out/Mode"'

# Scale.dml
hadoop jar SystemML.jar -f DMLScripts/descriptivestats/Scale.dml -args '"./data/S/in/vector"' 10000 '"./data/S/in/prob"' 5 '"./data/S/out/mean"' '"./data/S/out/std"' '"./data/S/out/se"' '"./data/S/out/var"' '"./data/S/out/cv"' '"./data/S/out/min"' '"./data/S/out/max"' '"./data/S/out/rng"' '"./data/S/out/g1"' '"./data/S/out/se_g1"' '"./data/S/out/g2"' '"./data/S/out/se_g2"' '"./data/S/out/median"' '"./data/S/out/iqm"' '"./data/S/out/out_minus"' '"./data/S/out/out_plus"' '"./data/S/out/quantile"' 

# CategoricalCategorical.dml 
hadoop jar SystemML.jar -f DMLScripts/descriptivestats/CategoricalCategorical.dml -args '"./data/CC/in/A"' 10000 '"./data/CC/in/B"' '"./data/CC/out/pValue"' '"./data/CC/out/Cramers_V"'

# ScaleScale.dml
hadoop jar SystemML.jar -f DMLScripts/descriptivestats/ScaleScale.dml -args '"./data/SS/in/X"' 100000 '"./data/SS/in/Y"' '"./data/SS/out/PearsonR"'

# ScaleCategorical.dml
hadoop jar SystemML.jar -f DMLScripts/descriptivestats/ScaleCategorical.dml -args '"./data/SC/in/A"' 10000 '"./data/SC/in/Y"' '"./data/SC/out/VarY"' '"./data/SC/out/MeanY"' '"./data/SC/out/CFreqs"' '"./data/SC/out/CMeans"' '"./data/SC/out/CVars"' '"./data/SC/out/Eta"' '"./data/SC/out/AnovaF"'

# OrdinalOrdinal.dml
hadoop jar SystemML.jar -f DMLScripts/descriptivestats/OrdinalOrdinal.dml -args '"./data/OO/in/A"' 10000 '"./data/OO/in/B"' '"./data/OO/out/Spearman"' 

# GNMF.dml
hadoop jar SystemML.jar -f DMLScripts/GNMF.dml -args '"./data/GNMF/in/v"' '"./data/GNMF/in/w"' '"./data/GNMF/in/h"' 2000 1500 50 3 '"./data/GNMF/out/w"' '"./data/GNMF/out/h"'

# HITS.dml
hadoop jar SystemML.jar -f DMLScripts/HITS.dml -args '"./data/HITS/in/G"' 2 1000 1000 0.000001 '"./data/HITS/out/hubs"' '"./data/HITS/out/authorities"'

# kMeans.dml
hadoop jar SystemML.jar -f DMLScripts/kMeans.dml -args '"./data/KMEANS/in/M"' 100 10 '"./data/KMEANS/out/kcenters"' 

# L2SVM.dml
hadoop jar SystemML.jar -f DMLScripts/L2SVM.dml -args '"./data/L2SVM/in/X"' '"./data/L2SVM/in/Y"' 1000 100 0.00000001 1 3 '"./data/L2SVM/out/w"' 

# LinearLogReg.dml
hadoop jar SystemML.jar -f DMLScripts/LinearLogReg.dml -args '"./data/LLR/in/X"' 100 50 '"./data/LLR/in/Xt"' 25 50 '"./data/LLR/in/y"' '"./data/LLR/in/yt"' '"./data/LLR/out/w"'

# LinearRegresssion.dml
hadoop jar SystemML.jar -f DMLScripts/LinearRegression.dml -args '"./data/LR/in/v"' 50 30 '"./data/LR/in/y"' 0.00000001 '"./data/LR/out/w"' 

# Outlier.dml
hadoop jar SystemML.jar -f DMLScripts/Outlier.dml -args '"./data/OUTLIER/in/M"' 100 10 '"./data/OUTLIER/out/o"' 

# PageRank.dml
hadoop jar SystemML.jar -f DMLScripts/PageRank.dml -args '"./data/PR/in/g"' '"./data/PR/in/p"' '"./data/PR/in/e"' '"./data/PR/in/u"' 1000 1000 0.85 3 '"./data/PR/out/w"'

# SeqMiner.dml
hadoop jar SystemML.jar -f DMLScripts/SeqMiner.dml -args '"./data/SM/in/M"' 5 10 '"./data/SM/out/fseq"' '"./data/SM/out/sup"' 