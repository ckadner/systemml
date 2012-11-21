library(Matrix)
X = readMM("features22954_mm.mtx")
y = X[,1]
X = X[,2:ncol(X)]
lemon_idx = which(y==1)
non_lemon_idx = which(y==-1)
train_lemon_idx = lemon_idx[1:round(0.75*length(lemon_idx))]
beg_pos = round(0.75*length(lemon_idx))+1
test_lemon_idx = lemon_idx[beg_pos:length(lemon_idx)]
train_non_lemon_idx = non_lemon_idx[1:round(0.75*length(non_lemon_idx))]
beg_pos = 1+round(0.75*length(non_lemon_idx))
test_non_lemon_idx = non_lemon_idx[beg_pos:length(non_lemon_idx)]
train_idx = c(train_lemon_idx, train_non_lemon_idx)
test_idx = c(test_lemon_idx, test_non_lemon_idx)
Xt = X[test_idx,]
yt = y[test_idx]
X = X[train_idx,]
y = y[train_idx]

writeMM(as(X, "CsparseMatrix"), "features22954.train.X.mtx", format="text")
writeMM(as(y, "CsparseMatrix"), "features22954.train.y.mtx", format="text")
writeMM(as(Xt, "CsparseMatrix"), "features22954.test.X.mtx", format="text")
writeMM(as(yt, "CsparseMatrix"), "features22954.test.y.mtx", format="text")


