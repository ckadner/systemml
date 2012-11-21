library(glmnet)

date()
X_extra = readMM("features250.csv.CV.mtx")
date()
y = X_extra[,2]
X = X_extra[,3:251]

mat_y = as.matrix(y)
num_pos = sum(mat_y==1)
num_neg = sum(mat_y==-1)
C = ifelse(mat_y==1, 1, num_pos/num_neg)
C_arr = c(C)
date()
fit_std = cv.glmnet(X, factor(mat_y), alpha=0, standardize=TRUE, weights=C_arr, family="binomial", type.measure="auc")
date()
jpeg ("auc_full.jpg")
plot(fit_std)
dev.off()
