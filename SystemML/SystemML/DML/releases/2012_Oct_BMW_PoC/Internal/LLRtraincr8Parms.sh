#!/bin/bash

hadoop jar ./SystemML.jar  -f LLRtraincr8Parms.dml -config=./SystemML-config.xml -args $1
