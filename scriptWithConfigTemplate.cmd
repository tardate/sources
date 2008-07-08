@echo off
REM $Id: scriptWithConfigTemplate.cmd,v 1.2 2008/05/20 15:28:56 paulg Exp $

setlocal

echo Welcome to %0

REM Initialise the config flag [CONFIGSET] and config file [LOCALCONF]
REM You must name the config file .bat or .cmd to ensure Windows can execute it cleanly
set CONFIGSET=NO

REM this sets LOCALCONF to be a config file in the conf subdirectory relative to this script,
REM named ThisScriptName-ComputerName.cmd
set LOCALCONF=%~dp0conf\%~n0-%COMPUTERNAME%.cmd

REM ===============================================================
REM Configuration section
REM ---------------------------------------------------------------
if "%LOCALCONF%"=="" goto config_help  
goto config_do


:config_help
echo This is a configuration help script
echo Call from another script with first parameter being the config file name
echo This script will set the variable CONFIGSET
echo   CONFIGSET=NO  in the case of error or undefined configuration
echo   CONFIGSET=YES in the case where configuration has been successfully read 
goto config_exit


:config_do
REM handle configuration file
IF EXIST %LOCALCONF% goto config_cont

REM generate default setting file
REM adapt this to you needs. Here are some samples
echo REM configuration file> %LOCALCONF%
echo set JAVA_HOME=C:\bin\jdk1.6.0_03>> %LOCALCONF%
echo set TMPFILE=c:\temp\mytemp.txt>> %LOCALCONF%
echo set SUBJECT=A subject line>> %LOCALCONF%
echo set DBUID=dbusername>> %LOCALCONF%
echo set DBPWD=dbpassword>> %LOCALCONF%

echo #
echo # Local configuration not yet set.
echo # A default configuration file (%LOCALCONF%) has been created.
echo # Review and edit this file, then run this process again.
echo #
goto config_exit


:config_cont
call %LOCALCONF%
set CONFIGSET=YES


:config_exit
if "%CONFIGSET%"=="YES" goto config_ok
echo Configuration is not set
goto exit
:config_ok
REM ---------------------------------------------------------------
REM Configuration section ends
REM ===============================================================


echo The main script starts from here.

echo The following configuration is set:
echo   JAVA_HOME=%JAVA_HOME%
echo   TMPFILE=%TMPFILE%
echo   SUBJECT=%SUBJECT%
echo   DBUID=%DBUID%
echo   DBPWD=%DBPWD%


:exit
endlocal