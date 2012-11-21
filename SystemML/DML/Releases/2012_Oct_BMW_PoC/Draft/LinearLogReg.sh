#!/bin/bash -x

export HADOOP_OPTS=-Xmx28g

hadoop jar ./SystemML.jar -f LinearLogReg1000.dml -config=./SystemML-config.xml -debug -args bjr/logreg/clean.X.mtx bjr/logreg/clean.y.mtx bjr/logreg/clean.Xt.mtx bjr/logreg/clean.yt.mtx bjr/logreg/clean.w.mtx
#hadoop jar ./SystemML.jar -f LinearLogReg.dml -config=./SystemML-config.xml -debug -args $1".Train1_X.mtx" $1".Test1_X.mtx" $1".Train1_Y.mtx" $1".Test1_Y.mtx" $1".Train1_W_new.mtx"
#hadoop jar ./SystemML.jar -f LinearLogReg.dml -config=./SystemML-config.xml -args $1".Train2_X.mtx" $1".Test2_X.mtx" $1".Train2_Y.mtx" $1".Test2_Y.mtx" $1".Train2_W.mtx"
#hadoop jar ./SystemML.jar -f LinearLogReg.dml -config=./SystemML-config.xml -args $1".Train3_X.mtx" $1".Test3_X.mtx" $1".Train3_Y.mtx" $1".Test3_Y.mtx" $1".Train3_W.mtx"
#hadoop jar ./SystemML.jar -f LinearLogReg.dml -config=./SystemML-config.xml -args $1".Train4_X.mtx" $1".Test4_X.mtx" $1".Train4_Y.mtx" $1".Test4_Y.mtx" $1".Train4_W.mtx"


