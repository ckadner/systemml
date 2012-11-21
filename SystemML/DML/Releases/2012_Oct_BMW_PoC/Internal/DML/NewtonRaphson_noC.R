# JUnit test class: dml.test.integration.applications.LinearLogReg.java
# command line invocation assuming $LLR_HOME is set to the home of the R script
# Rscript $LLR_HOME/LinearLogReg.R $LLR_HOME/in/ $LLR_HOME/expected/

args <- commandArgs(TRUE)

library("Matrix")
#library("batch")
# Usage:  /home/vikas/R-2.10.1/bin/R --vanilla --args Xfile X yfile y Cval 2 tol 0.01 maxiter 100 < linearLogReg.r

# Solves Linear Logistic Regression using Trust Region methods. 
# Can be adapted for L2-SVMs and more general unconstrained optimization problems also
# setup optimization parameters (See: Trust Region Newton Method for Logistic Regression, Lin, Weng and Keerthi, JMLR 9 (2008) 627-650)

options(warn=-1)

#C = 2; 
alpha = 0.01
beta = 0.5
tol = 0.0001
maxiter = 100

# read (training and test) data files -- should be in matrix market format. see data.mtx 
X = readMM(args[1]);
Xt = readMM(args[3]);

N = nrow(X)
D = ncol(X)
# change suggested by Prithvi: Nt = nrow(Xt)
# in DML: Nt = nrow(Xt) - sum(ppred(rowSums(abs(Xt)), 0, "=="))
Nt = nrow(Xt) - length(which(rowSums(abs(Xt))== 0))


# read (training and test) labels
y = readMM(args[2]);
yt = readMM(args[4]);

y_arr = c(as.matrix(y))
num_pos = length(which(y_arr==1))
num_neg = length(which(y_arr==-1))

# read weights
#C = readMM(args[5])
y_bool = (y_arr==1)
C_arr = ifelse(y_bool, 1, num_pos/num_neg)
C = matrix(C_arr, N, 1)

# initialize w
w = matrix(0,D,1)
o = X %*% w
logistic = 1.0/(1.0 + exp(-y*o))
 
# number of iterations
iter = 0

converge = FALSE

Id = Diagonal(D)

while(!converge) {

	logistic = 1.0/(1.0 + exp(-y*o))
	obj = 0.5 * t(w) %*% w + sum(-C*log(logistic))
	grad = w + t(X) %*% (C*(logistic - 1)*y)
	logisticD = logistic*(1-logistic)
	norm_grad = sqrt(sum(grad*grad))
	d = C*logisticD
	DD=Matrix(Diagonal(x=as.vector(d)))
	hessian = t(X) %*% (DD %*% X) + Id	

	#newton = solve(hessian, -grad)
	newton = -grad
	n = X %*% newton
	s = t(grad) %*% newton
	t = 1
	wnew = w + newton
	onew = o + n 
	while(as.matrix(0.5*t(wnew) %*% wnew + sum(C*log((1.0 + exp(-y*onew)))))  > as.matrix(obj + alpha*t*s)) {
		t = beta*t;
		wnew = w + t*newton
		onew = o + t*n
	}
		
	w = wnew
	o = onew 
	ot = Xt %*% w

	tp = sum(ot>0 & yt==1)
	fn = sum(ot<=0 & yt==1)
	fp = sum(ot>0 & yt==-1)
	print(paste("tp=", tp, " fp=", fp, " fn=", fn))
	precision = tp/(tp+fp)
	recall = tp/(tp+fn)
	print(paste("precision=", precision, " recall=", recall))

	correct = sum((yt*ot)>0)
	iter = iter + 1
	converge = (norm_grad < tol) | (iter>maxiter)
	
	print(paste("Iter=", iter))
	print(paste("Obj=", as.matrix(obj)))
	print(paste("GradNorm=",norm_grad))
	print(paste("Accuracy=", correct*100/Nt))
	print(paste("Converge=", converge))
}

writeMM(as(w,"CsparseMatrix"), args[5], format = "text")


