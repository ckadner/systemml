#for precicion+recall+curve
library(bitops)
library(caTools)
library(glmnet)

X_file = "../data_sen/train4.X.mtx"
y_file = "../data_sen/train4.y.mtx"
Xt_file = "../data_sen/test4.X.mtx"
yt_file = "../data_sen/test4.y.mtx"

X = readMM(X_file)
y = readMM(y_file)
mat_y = as.matrix(y)
num_pos = sum(mat_y==1)
num_neg = sum(mat_y==-1)
C = ifelse(mat_y==1, 1, num_pos/num_neg)
C_arr = c(C)
date()
fit_std = cv.glmnet(X, factor(mat_y), alpha=0, standardize=TRUE, weights=C_arr, family="binomial", type.measure="auc")
date()

jpeg ("auc_1.jpg")
plot(fit_std)
dev.off()


Xt = readMM(Xt_file)
yt = readMM(yt_file)
classes = predict(fit_std, Xt, type="class")
numeric_classes = as.numeric(classes)
mat_yt = as.matrix(yt)
factor_yt= factor(mat_yt)
tp = sum((factor_yt == 1) & (numeric_classes == 1))
fp = sum((factor_yt == -1) & (numeric_classes == 1))
fn = sum((factor_yt == 1) & (numeric_classes == -1))
tp/(tp+fp)*100 #precision
tp/(tp+fn)*100 #recall
#for auc
responses = predict(fit_std, Xt, type="response")
roc = colAUC(responses, factor(mat_yt), plotROC=TRUE)
roc
