#################################################################################
#
# IBM Confidential
#
# OCO Source Materials
#
# (C) Copyright IBM Corp. 2009, 2010, 2011
#
# The source code for this program is not published or
#
# otherwise divested of its trade secrets, irrespective of
#
# what has been deposited with the U.S. Copyright Office.
#
#################################################################################

RUN=1016-1
#HDPATH=/data/svlearn
HDPATH=bmw


# run the arg1 as a shell script. time & log it
runtimed() {
  local script=$1
  shift
  time ./$script.sh "$@" 2>&1 | tee $script.$RUN.log
}


#
# Given feature vectors for ...m1 (-1 = regular car) and p1 (+1 = reacquired car)
#     ${HDPATH}"/features22954.m1.mtx"
#     ${HDPATH}"/features22954.p1.mtx"
#

# FOLD CREATION: Create 4 folds for -1 and +1. This is done in 2 runs of DML crt8Folds.dml
# This takes approx. 4 hours for m1, and 2 mins for p1.
#     Input:  ...m1.mtx
#             ...p1.mtx
#     Output: ...m1F1.mtx, ...m1F2.mtx, ...m1F3.mtx, ...m1F4.mtx
#             ...p1F1.mtx, ...p1F2.mtx, ...p1F3.mtx, ...p1F4.mtx

#runtimed cr8Folds ${HDPATH}"/features22954.p1"
#runtimed cr8FoldsCondense ${HDPATH}"/features22954.p1"

runtimed cr8Folds ${HDPATH}"/features22954.m1"
runtimed cr8FoldsCondense ${HDPATH}"/features22954.m1"


# TRAIN/TEST CREATION: Combine the 4 m1 and p1 folds into 4 Train/Test
# sets. This is done in 4 runs of DML cr8TrainTest.dml
# This takes approx. 10 mins per run.
#     Use:  ...p1F1.mtx, ...p1F2.mtx, ...p1F3.mtx, ...p1F4.mtx
#           ...m1F1.mtx, ...m1F2.mtx, ...m1F3.mtx, ...m1F4.mtx
#     Output: ...Train1.mtx, ...Test1.mtx
#             ...Train2.mtx, ...Test2.mtx
#             ...Train3.mtx, ...Test3.mtx
#             ...Train4.mtx, ...Test4.mtx

#runtimed cr8TrainTest ${HDPATH}"/features22954"

# XY SPLITTING: Split TrainTest into X and y for logreg. This is done using
# splitXY.sh in 8 invocations.
# This takes approx.
#     Input:  ...Train1.mtx ...Test1.mtx
#             ...Train2.mtx ...Test2.mtx
#             ...Train3.mtx ...Test3.mtx
#             ...Train4.mtx ...Test4.mtx
#     Output: ...Train1_X.mtx  ...Train1_y.mtx
#             ...Train2_X.mtx  ...Train2_y.mtx
#             ...Train3_X.mtx  ...Train3_y.mtx
#             ...Train4_X.mtx  ...Train4_y.mtx

#runtimed splitXY ${HDPATH}"/features22954"

# LINEAR LOGISTIC REGRESSION (LLR) TRAINING on 4 Train/Test sets
# Run logreg on different Train/Test sets. This is done in DML LLRtrain.dml
# with also does parameter selection.

# script to create 60 interesting parameter setting that will be tried.
#runtimed LLRtraincr8Parms ${HDPATH}"/LLRparams.mtx"

#runtimed LLRtrain  ${HDPATH}"/features22954.Train1_X.mtx" ${HDPATH}"/features22954.Train1_y.mtx" ${HDPATH}"/LLRparams.mtx" ${HDPATH}"/features22954.Train1_w.mtx"
#runtimed LLRtrain  ${HDPATH}"/features22954.Train2_X.mtx" ${HDPATH}"/features22954.Train2_y.mtx" ${HDPATH}"/LLRparams.mtx" ${HDPATH}"/features22954.Train2_w.mtx"
#runtimed LLRtrain  ${HDPATH}"/features22954.Train3_X.mtx" ${HDPATH}"/features22954.Train3_y.mtx" ${HDPATH}"/LLRparams.mtx" ${HDPATH}"/features22954.Train3_w.mtx"
#runtimed LLRtrain  ${HDPATH}"/features22954.Train4_X.mtx" ${HDPATH}"/features22954.Train4_y.mtx" ${HDPATH}"/LLRparams.mtx" ${HDPATH}"/features22954.Train4_w.mtx"


# LLR SCORING on 4 Train/Test sets

#runtimed LLRscore  ${HDPATH}"/features22954.Test1_X.mtx" ${HDPATH}"/features22954.Test1_y.mtx" ${HDPATH}"/features22954.Train1_w.mtx" ${HDPATH}"/LLRparams.mtx" ${HDPATH}"/features22954.Test1_probs.mtx"
#runtimed LLRscore  ${HDPATH}"/features22954.Test2_X.mtx" ${HDPATH}"/features22954.Test2_y.mtx" ${HDPATH}"/features22954.Train2_w.mtx" ${HDPATH}"/LLRparams.mtx" ${HDPATH}"/features22954.Test2_probs.mtx"
#runtimed LLRscore  ${HDPATH}"/features22954.Test3_X.mtx" ${HDPATH}"/features22954.Test3_y.mtx" ${HDPATH}"/features22954.Train3_w.mtx" ${HDPATH}"/LLRparams.mtx" ${HDPATH}"/features22954.Test3_probs.mtx"
#runtimed LLRscore  ${HDPATH}"/features22954.Test4_X.mtx" ${HDPATH}"/features22954.Test4_y.mtx" ${HDPATH}"/features22954.Train4_w.mtx" ${HDPATH}"/LLRparams.mtx" ${HDPATH}"/features22954.Test4_probs.mtx"


