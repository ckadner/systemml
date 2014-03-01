///////////////////////////////////////////////////////////////////////////////
//
// IBM Confidential
//
// OCO Source Materials
//
// (C) Copyright IBM Corp. 2009, 2010, 2011
//
// The source code for this program is not published or
//
// otherwise divested of its trade secrets, irrespective of
//
// what has been deposited with the U.S. Copyright Office.
//
///////////////////////////////////////////////////////////////////////////////

# 
# Main Driver to implement flow from Car Feature Vector in CSV format to
# running logistic regression. This flow goes to BMW only partially.
#

#
# SQL code to Create export files for dwh data warehouse: ./Data/iter2/ml*.del
#
# ./Internal/dwh_export.sql


#
# SQL code to Import export files into local DB2 and create features64 vectors: ./Data/iter2/features64.del
#
# ./Internal/cr8features64.sql


#
# JAQL code Transform features64.del file to mtx: ./Data/iter2/features21885.mtx
#
# ./Internal/cr8features21885.sh

#
# R code to do binning: in principle, it takes features21885.mtx, writes label
# file _y.mtx, and features1122_bins.mtx that contains 1122 bin variables for
# cols 2-54 as well as binning map (featuresBinFeaturesIndices.mtx).  As R
# cannot load features21885.mtx, we split off the categorical variables that
# we want to bin (features21885_1To54.mtx).The output contains the 1122
# categorical features created by binning using the scale features in the
# 21885 dataset (note that col indices in this file start from 21832 since
# there were 21831 categorical features in the original dataset). Produces
# features21885_1To54_binned.mtx.  Use linux tools to "stitch" together above
# files and produce: features22953_mm.mtx (R Matrix)
#
# ./Internal/binning.R

#
# Code to take features22953_mm.mtx and features22953_y_mm.mtx, put the y
# column into the 1st column of the output, and separate samples into -1 and
# +1 to produce 2 output files: features22954_mm_m1.mtx and
# features22954_mm_p1.mtx
#
# In Jaql ... ./Internal/cbind.jaql
# Linux       cat features22954.mtx >> features22954_mm.mtx
# In R    ... ./Internal/separate_m1p1.R
#

#
# Create SystemML matrices
#
# tail -n +3 features22954_mm.m1.mtx   > features22954.m1.mtx
# tail -n +3 features22954_mm.p1.mtx   > features22954.p1.mtx
#

