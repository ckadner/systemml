#!/bin/bash -x
export HADOOP_OPTS=-Xmx15g

base=$1

# hadoop fs -copyToLocal bmw/$1.m1.mtx.mtd /tmp/
# hadoop fs -copyToLocal bmw/$1.p1.mtx.mtd /tmp/
# jaqlshell -e jaqlGet("file:///tmp/$1.m1.mtx.mtd").rows + jaqlGet("file:///tmp/$1.p1.mtx.mtd").rows 

xx=450000
yy=$[3 * $xx]

m1F1=$base.m1F1.mtx 
p1F1=$base.p1F1.mtx
m1F2=$base.m1F2.mtx
p1F2=$base.p1F2.mtx
m1F3=$base.m1F3.mtx
p1F3=$base.p1F3.mtx
m1F4=$base.m1F4.mtx
p1F4=$base.p1F4.mtx

hadoop jar ./SystemML.jar -f cr8TrainTest.dml -config=./SystemML-config.xml -args $m1F1 $p1F1 $m1F2 $p1F2 $m1F3 $p1F3 $m1F4 $p1F4 $xx $yy $base.Test1.mtx $base.Train1.mtx
hadoop jar ./SystemML.jar -f cr8TrainTest.dml -config=./SystemML-config.xml -args $m1F2 $p1F2 $m1F1 $p1F1 $m1F3 $p1F3 $m1F4 $p1F4 $xx $yy $base.Test2.mtx $base.Train2.mtx
hadoop jar ./SystemML.jar -f cr8TrainTest.dml -config=./SystemML-config.xml -args $m1F3 $p1F3 $m1F1 $p1F1 $m1F2 $p1F2 $m1F4 $p1F4 $xx $yy $base.Test3.mtx $base.Train3.mtx
hadoop jar ./SystemML.jar -f cr8TrainTest.dml -config=./SystemML-config.xml -args $m1F4 $p1F4 $m1F1 $p1F1 $m1F2 $p1F2 $m1F3 $p1F3 $xx $yy $base.Test4.mtx $base.Train4.mtx
