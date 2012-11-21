library(Matrix)
M = readMM("features22954_mm.mtx")
p1 = M[which(M[,1]==1),]
m1 = M[which(M[,1]==-1),]
writeMM(as(p1, "CsparseMatrix"), "features22954_mm.p1.mtx", format="text")
writeMM(as(m1, "CsparseMatrix"), "features22954_mm.m1.mtx", format="text")
