#!/bin/bash -x
export HADOOP_OPTS=-Xmx30g

time hadoop jar ./SystemML.jar -f cr8FoldsCondense.dml -config=./SystemML-config.xml -args "$1F1.mtx"
time hadoop jar ./SystemML.jar -f cr8FoldsCondense.dml -config=./SystemML-config.xml -args "$1F2.mtx"
time hadoop jar ./SystemML.jar -f cr8FoldsCondense.dml -config=./SystemML-config.xml -args "$1F3.mtx"
time hadoop jar ./SystemML.jar -f cr8FoldsCondense.dml -config=./SystemML-config.xml -args "$1F4.mtx"
