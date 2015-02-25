#!/bin/bash

export HADOOP_OPTS=-Xmx6g

#Command line parameters
NUM_FEATURES=22953 #(adjust if adding bias column)
MAXITER=1000

hadoop jar ./SystemML.jar  -f LLRtrain.dml -exec singlenode -config=./SystemML-config.xml -args $1 $2 $3 $NUM_FEATURES $MAXITER $4






