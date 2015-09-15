#!/bin/bash

# error help print
printUsageExit()
{
cat << EOF
Usage: $0 <dml-filename> [arguments] [-help]
    -help     - Print this usage message and exit
EOF
  exit 1
}
#    Script internally invokes 'java -Xmx4g -Xms4g -Xmn400m -jar StandaloneSystemML.jar -f <dml-filename> -exec singlenode -config=SystemML-config.xml [Optional-Arguments]'

while getopts "h:" options; do
  case $options in
    h ) echo Warning: Help requested. Will exit after usage message;
        printUsageExit
        ;;
    \? ) echo Warning: Help requested. Will exit after usage message;
        printUsageExit
        ;;
    * ) echo Error: Unexpected error while processing options;
  esac
done

if [ -z $1 ] ; then
    echo "Wrong Usage.";
    printUsageExit;
fi


# find the systemML root path which contains the bin folder and the system-ml folder
PROJECT_ROOT_PATH=$( cd $(dirname $0)/.. ; pwd -P )

# Peel off first argument so that $@ contains arguments to DML script
SCRIPT_FILE=$1
shift

if [ ! -f $SCRIPT_FILE ]
then
  # strip the path from the script file
  SCRIPT_FILE_NAME=$(basename $SCRIPT_FILE)
  # find the correct path of the script file (varies between packages)
  SCRIPT_FILE=$( find $PROJECT_ROOT_PATH/system-ml/scripts -name $SCRIPT_FILE_NAME )
  echo "using script: $SCRIPT_FILE"
fi

CLASSPATH=${PROJECT_ROOT_PATH}/system-ml/target/lib/*;

#SYSTEM_ML_JAR=$( find $PROJECT_ROOT_PATH/system-ml/target/system-ml-*-SNAPSHOT.jar )
SYSTEM_ML_JAR=$PROJECT_ROOT_PATH/system-ml/target/classes

CLASSPATH=${CLASSPATH}:${SYSTEM_ML_JAR};

# invoke the jar with options and arguments
java -Xmx8g -Xms4g -Xmn1g -cp ${CLASSPATH} com.ibm.bi.dml.api.DMLScript \
     -f ${SCRIPT_FILE} -exec singlenode \
     -config=${PROJECT_ROOT_PATH}/system-ml/src/main/standalone"/SystemML-config.xml" \
     $@

