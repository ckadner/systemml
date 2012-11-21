library(Matrix)
X = readMM("features21885_1To54.mtx")
y = X[,1]
writeMM(as(Matrix(y), "CsparseMatrix"), "new_y.mtx", format="text")
rm(y)
X2 = c()
num_samples = nrow(X)
j=2
idx = Matrix(0, 54, 2)
beg = 21832
while(j<=54){
  h = hist(X[,j], plot=F)
  end = beg+length(h$breaks)-2
  idx[j,1] = beg
  idx[j,2] = end
  beg = end+1
  i=1
  while(i < length(h$breaks)){
    new_col = ifelse(X[,j]>=h$breaks[i] & X[,j]<h$breaks[i+1], 1, 0)
    if(i==length(h$breaks)-1){
      new_col = new_col + ifelse(X[,j]==h$breaks[i+1], 1, 0)
    }
    X2 = cbind(X2, matrix(new_col, num_samples, 1))
    print(paste(j, ": ", i, "/", length(h$breaks)))
    i = i + 1
  }
  print(j)
  j = j+1
}
writeMM(as(Matrix(X2), "CsparseMatrix"), "features21884_1To54_binned.mtx", format="text")
writeMM(as(Matrix(idx), "CsparseMatrix"), "binFeatureIndices.mtx",
format="text")
