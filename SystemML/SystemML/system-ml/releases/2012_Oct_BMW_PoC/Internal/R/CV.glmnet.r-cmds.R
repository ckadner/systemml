library(bitops)
library(caTools)

library(glmnet)

X_extra = readMM("features250.csv.CV.mtx")
y = X_extra[,2]
X = X_extra[,3:251]
mat_y = as.matrix(y)
num_pos = sum(mat_y==1)
num_neg = sum(mat_y==-1)
C = ifelse(mat_y==1, 1, num_pos/num_neg)
C_arr = c(C)
fit_std = cv.glmnet(X, factor(mat_y), alpha=0, standardize=TRUE, weights=C_arr, family="binomial", type.measure="auc")
plot(fit_std)

X = readMM("../workspace1/DML/scripts/features250.8k8k.mtx")
y = readMM("../workspace1/DML/scripts/labels.8k8k.mtx")
mat_y = as.matrix(y)
num_pos = sum(mat_y==1)
num_neg = sum(mat_y==-1)
C = ifelse(mat_y==1, 1, num_pos/num_neg)
C_arr = c(C)
fit_std = cv.glmnet(X, factor(mat_y), alpha=0, standardize=TRUE, weights=C_arr, family="binomial", type.measure="auc")
plot(fit_std)

#for precicion+recall+curve
library(bitops)
library(caTools)
library(glmnet)

X_file = "train1.X.mtx"
y_file = "train1.y.mtx"
Xt_file = "test1.X.mtx"
yt_file = "test1.y.mtx"

X = readMM(X_file)
y = readMM(y_file)
mat_y = as.matrix(y)
num_pos = sum(mat_y==1)
num_neg = sum(mat_y==-1)
C = ifelse(mat_y==1, 1, num_pos/num_neg)
C_arr = c(C)
fit_std = cv.glmnet(X, factor(mat_y), alpha=0, standardize=TRUE, weights=C_arr, family="binomial", type.measure="auc")

Xt = readMM(Xt_file)
yt = readMM(yt_file)
classes = predict(fit_std, Xt, type="class")
numeric_classes = as.numeric(classes)
mat_yt = as.matrix(yt)
factor_yt= factor(mat_yt)
tp = sum((factor_yt == 1) & (numeric_classes == 1))
fp = sum((factor_yt == -1) & (numeric_classes == 1))
fn = sum((factor_yt == 1) & (numeric_classes == -1))
tn = sum((factor_yt == -1) & (numeric_classes == -1))
tp/(tp+fp)*100 #precision
tp/(tp+fn)*100 #recall
#for auc
responses = predict(fit_std, Xt, type="response")
jpeg("ROC.jpg")
colAUC(responses, factor(mat_yt), plotROC=TRUE)
dev.off()




for(thresh in seq(0,1,0.1)) {
#thresh = 0
tp = sum((yt == 1) & (responses>thresh))
fp = sum((yt == -1) & (responses>thresh))
fn = sum((yt == 1) & (responses<=thresh))
prec = tp/(tp+fp)*100 #precision
rec = tp/(tp+fn)*100 #recall
print(paste(thresh, " " , prec, "(P) ", rec, "(R)"))
}
