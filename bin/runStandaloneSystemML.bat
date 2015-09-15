@ECHO OFF

IF "%~1" == ""  GOTO Err
IF "%~1" == "-help" GOTO Msg
IF "%~1" == "-h" GOTO Msg

setLocal EnableDelayedExpansion


SET USER_DIR=%CD%

pushd %~dp0..
SET PROJECT_ROOT_PATH=%CD%
popd

:: if the present working directory is the project root, use the temp folder as user.dir
IF %PROJECT_ROOT_PATH%==%USER_DIR% (
  SET USER_DIR=%PROJECT_ROOT_PATH%\temp
)

ECHO project root path: %PROJECT_ROOT_PATH%
ECHO working directory: %USER_DIR%



:: if the SystemML-config.xml does not exis, create it from the template
IF NOT EXIST %PROJECT_ROOT_PATH%\conf\SystemML-config.xml (
  copy %PROJECT_ROOT_PATH%\conf\SystemML-config.xml.template ^
       %PROJECT_ROOT_PATH%\conf\SystemML-config.xml > nul
  echo created %PROJECT_ROOT_PATH%\conf\SystemML-config.xml
)

:: if the log4j.properties do not exis, create them from the template
IF NOT EXIST %PROJECT_ROOT_PATH%\conf\log4j.properties (
  copy %PROJECT_ROOT_PATH%\conf\log4j.properties.template ^
       %PROJECT_ROOT_PATH%\conf\log4j.properties > nul
  echo created %PROJECT_ROOT_PATH%\conf\log4j.properties
)

SET SCRIPT_FILE=%1

:: if the script file path was omitted, try to complete the script path
IF NOT EXIST %SCRIPT_FILE% (
  FOR /R %PROJECT_ROOT_PATH% %%f IN (%SCRIPT_FILE%) DO IF EXIST %%f ( SET SCRIPT_FILE_FOUND=%%f )
)

IF NOT EXIST %SCRIPT_FILE% IF NOT DEFINED SCRIPT_FILE_FOUND (
  echo Could not find DML script: %SCRIPT_FILE%
  GOTO Err
) ELSE (
  SET SCRIPT_FILE=%SCRIPT_FILE_FOUND%
  echo DML script: %SCRIPT_FILE_FOUND%
)


:: the hadoop winutils
SET HADOOP_HOME=%PROJECT_ROOT_PATH%\system-ml\target\lib\hadoop

:: add dependent libraries to classpath (since Java 1.6 we can use wildcards)
set CLASSPATH=%PROJECT_ROOT_PATH%\system-ml\target\lib\*

:: add compiled SystemML classes to classpath
set CLASSPATH=%CLASSPATH%;%PROJECT_ROOT_PATH%\system-ml\target\classes

echo classpath: !CLASSPATH!


for /f "tokens=1,* delims= " %%a in ("%*") do set ALLBUTFIRST=%%b

:: invoke the jar with options and arguments
java -Xmx4g -Xms2g -Xmn400m ^
     -cp %CLASSPATH% ^
     -Duser.dir=%USER_DIR% ^
     com.ibm.bi.dml.api.DMLScript ^
     -f %SCRIPT_FILE% ^
     -exec singlenode ^
     -config=%PROJECT_ROOT_PATH%\conf\SystemML-config.xml ^
     %ALLBUTFIRST%

GOTO End

:Err
ECHO Wrong Usage. Please provide DML filename to be executed.
GOTO Msg

:Msg
ECHO Usage: runStandaloneSystemML.bat ^<dml-filename^> [arguments] [-help]
ECHO Script internally invokes 'java -Xmx4g -Xms4g -Xmn400m -jar jSystemML.jar -f ^<dml-filename^> -exec singlenode -config=SystemML-config.xml [Optional-Arguments]'

:End
