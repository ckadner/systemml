#!/bin/bash
#-------------------------------------------------------------
#
# (C) Copyright IBM Corp. 2010, 2015
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#-------------------------------------------------------------

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
    h ) echo Warning: Help requested. Will exit after usage message
        printUsageExit
        ;;
    \? ) echo Warning: Help requested. Will exit after usage message
        printUsageExit
        ;;
    * ) echo Error: Unexpected error while processing options
  esac
done

if [ -z "$1" ] ; then
    echo "Wrong Usage.";
    printUsageExit;
fi


# find the systemML root path which contains the bin folder and the system-ml folder
# tolerate path with spaces
SCRIPT_DIR=$(dirname "$0")
PROJECT_ROOT_DIR=$( cd "${SCRIPT_DIR}/.." ; pwd -P )

USER_DIR=$PWD

BUILD_DIR=${PROJECT_ROOT_DIR}/system-ml/target
HADOOP_LIB_DIR=${BUILD_DIR}/lib
DML_SCRIPT_CLASS=${BUILD_DIR}/classes/com/ibm/bi/dml/api/DMLScript.class

BUILD_ERR_MSG="You must build the project before running this script."
BUILD_DIR_ERR_MSG="Could not find target directory \"${BUILD_DIR}\". ${BUILD_ERR_MSG}"
HADOOP_LIB_ERR_MSG="Could not find required libraries \"${HADOOP_LIB_DIR}/*\". ${BUILD_ERR_MSG}"
DML_SCRIPT_ERR_MSG="Could not find \"${DML_SCRIPT_CLASS}\". ${BUILD_ERR_MSG}"

# check if the project had been built and the jar files exist
if [ ! -d "${BUILD_DIR}" ];        then echo "${BUILD_DIR_ERR_MSG}";  exit 1; fi
if [ ! -d "${HADOOP_LIB_DIR}" ];   then echo "${HADOOP_LIB_ERR_MSG}"; exit 1; fi
if [ ! -f "${DML_SCRIPT_CLASS}" ]; then echo "${DML_SCRIPT_ERR_MSG}"; exit 1; fi


echo "================================================================================"

# if the present working directory is the project root or bin folder, then use the temp folder as user.dir
if [ "$USER_DIR" = "$PROJECT_ROOT_DIR" ] || [ "$USER_DIR" = "$PROJECT_ROOT_DIR/bin" ]
then
  USER_DIR=${PROJECT_ROOT_DIR}/temp
  echo "Output dir: $USER_DIR"
fi


# if the SystemML-config.xml does not exis, create it from the template
if [ ! -f "${PROJECT_ROOT_DIR}/conf/SystemML-config.xml" ]
then
  cp "${PROJECT_ROOT_DIR}/conf/SystemML-config.xml.template" \
     "${PROJECT_ROOT_DIR}/conf/SystemML-config.xml"
  echo "... created ${PROJECT_ROOT_DIR}/conf/SystemML-config.xml"
fi

# if the log4j.properties do not exis, create them from the template
if [ ! -f "${PROJECT_ROOT_DIR}/conf/log4j.properties" ]
then
  cp "${PROJECT_ROOT_DIR}/conf/log4j.properties.template" \
     "${PROJECT_ROOT_DIR}/conf/log4j.properties"
  echo "... created ${PROJECT_ROOT_DIR}/conf/log4j.properties"
fi


# Peel off first argument so that $@ contains arguments to DML script
SCRIPT_FILE=$1
shift

# if the script file path was omitted, try to complete the script path
if [ ! -f "$SCRIPT_FILE" ]
then
  SCRIPT_FILE_NAME=$(basename $SCRIPT_FILE)
  SCRIPT_FILE_FOUND=$(find "$PROJECT_ROOT_DIR/system-ml/scripts" -name "$SCRIPT_FILE_NAME")
  if [ ! "$SCRIPT_FILE_FOUND" ]
  then
    echo "Could not find DML script: $SCRIPT_FILE"
    printUsageExit;
  else
    SCRIPT_FILE=$SCRIPT_FILE_FOUND
    echo "DML script: $SCRIPT_FILE"
  fi
fi


# add hadoop libraries which were generated by the build to the classpath
CLASSPATH=\"${BUILD_DIR}/lib/*\"

#SYSTEM_ML_JAR=$( find $PROJECT_ROOT_DIR/system-ml/target/system-ml-*-SNAPSHOT.jar )
SYSTEM_ML_JAR=\"${BUILD_DIR}/classes\"

CLASSPATH=${CLASSPATH}:${SYSTEM_ML_JAR}

echo "================================================================================"

# invoke the jar with options and arguments
CMD="java -Xmx8g -Xms4g -Xmn1g \
     -cp $CLASSPATH \
     -Dlog4j.configuration=file:'$PROJECT_ROOT_DIR/conf/log4j.properties' \
     -Duser.dir='$USER_DIR' \
     com.ibm.bi.dml.api.DMLScript \
     -f '$SCRIPT_FILE' \
     -exec singlenode \
     -config='$PROJECT_ROOT_DIR/conf/SystemML-config.xml' \
     $@"

eval ${CMD}

RETURN_CODE=$?

# if there was an error, display the full java command (in case some of the variable substitutions broke it)
if [ $RETURN_CODE -ne 0 ]
then
  echo "Failed to run SystemML. Exit code: $RETURN_CODE"
  LF=$'\n'


  # keep empty lines above for the line breaks
  echo "  ${CMD//     /$LF      }"
fi

