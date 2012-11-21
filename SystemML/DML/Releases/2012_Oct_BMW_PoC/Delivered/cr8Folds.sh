#!/bin/bash -x
export HADOOP_OPTS=-Xmx30g

time hadoop jar ./SystemML.jar -f cr8Folds.dml -exec singlenode -config=./SystemML-config.xml -args "$1"
