#!/bin/bash

export HADOOP_OPTS=-Xmx6g
NUM_FEATURES=22953 #(adjust if adding bias column)

hadoop jar ./SystemML.jar -f LLRscore.dml -exec singlenode -args $1 $2 $3 $4 $NUM_FEATURES $5

