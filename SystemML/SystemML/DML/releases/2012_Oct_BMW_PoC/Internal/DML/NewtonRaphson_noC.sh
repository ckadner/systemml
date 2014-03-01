fname="/user/reinwald/bjr/logreg/features250.csv.Train3_"

hadoop jar SystemML.jar -f NewtonRaphson_noC.dml -d -args $fname"X.mtx" $fname"Y.mtx" $fname"W.mtx" 1


