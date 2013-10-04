#!/bin/bash -x
export HADOOP_OPTS=-Xmx15g

time jaqlshell -jp . dataprep.jaql
