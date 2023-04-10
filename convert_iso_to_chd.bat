:: New batch file 2023
:: - Run in a folder to automatically batch convert all the possible files.
:: - Define a source folder to convert all the files in there.
:: - Define a single file to just convert that one file.

@ECHO OFF
:: This is a weird way to call CMD so that PowerShell also works as expected
CALL CMD /E:ON /C :Start
:Start
SETLOCAL EnableDelayedExpansion


::::: ---- SETTINGS ----
:: Copy files locally?
SET copyLocally=1
:: Delete source zip file on success? (1=yes, 0=no)
SET deleteSourceOnSuccess=1
:: Format to look at (lower case)
SET formatIN=iso
:: Format to save as (lower case)
SET formatOUT=chd
:: Where is the temp folder located?
SET mainTemp=c:\



::::: ---- PROGRAMMING ----
CALL :Startup
ECHO %_fBRed%^>^>%_fGreen% %formatINupper% to %formatOUTupper% Converter %_RESET%
ECHO %_fBRed%^>^>%_fGreen% Written by Oz %_RESET%
ECHO.
ECHO %_fBRed%^>^>%_fGreen% Current Settings: %_RESET%
ECHO %_fBRed%^>^>%_fGreen% copyLocally = %copyLocally% %_RESET%
ECHO %_fBRed%^>^>%_fGreen% deleteSourceOnSuccess = %deleteSourceOnSuccess% %_RESET%
ECHO %_fBRed%^>^>%_fGreen% mainTemp = %mainTemp% %_RESET%
ECHO.
ECHO.


:: Starting Logic
IF "%~1" == "-?" GOTO :Help
IF [%1] == [] GOTO :Nothing
SET _test=%~a1
SET _result=%_test:~0,1%
IF /I "%_result%" == "d" GOTO :Folder
IF /I "%_result%" == "-" GOTO :File
GOTO :End


:: Logic for 3 options.
:Nothing
ECHO %_fBRed%^>^>%_fGreen% No folder given, working off current directory. %_RESET%
CALL :Batch "%cd%"
GOTO :End

:Folder
ECHO %_fBRed%^>^>%_fGreen% Folder given. %_RESET%
CALL :Batch "%~1"
GOTO :End

:File
ECHO %_fBRed%^>^>%_fGreen% File was given. %_RESET%
IF "%~x1" EQU ".%formatIN%" (
	CALL :Compress "%~1"
) ELSE (
	ECHO %_fBRed%^>^>%_fGreen% ERROR: File type not supported. %_RESET%
    ECHO.
    GOTO :Help
)
GOTO :EOF


:Batch
ECHO %_fBRed%^>^>%_fGreen% Starting Batch %_RESET%
CALL :SetOriginalFolder "%~1"
for %%i in ("%originalFolder%\*.%formatIN%") do CALL :Compress "%%i"
ECHO %_fBRed%^>^>%_fGreen% Ended Batch %_RESET%
GOTO :End

:Compress
ECHO %_fBRed%^>^>%_fGreen% Starting compression %_RESET%
CALL :SetOriginalFolder "%~1"
SET "file=%~nx1"
SET "name=%~n1"


:: Creating Temp Folder and Moving file
IF %copyLocally% == 1 (
    ECHO %_fBRed%^>^>%_fGreen% Copy locally is ON %_RESET%
    SET "tmpPath=%mainTemp%\TEMP\%name%"
) ELSE (
    SET "tmpPath=%originalFolder%\%name%"
)
CALL :CreateTemp "%tmpPath%"
IF %copyLocally% == 1 (ROBOCOPY "%originalFolder%" "%tmpPath%" "%file%" /MT:16 /COMPRESS)

:: Compressing the file
ECHO %_fBRed%^>^>%_fGreen% Compressing: %name% %_RESET%
CALL chdman createcd -i "%tmpPath%/%file%" -o "%tmpPath%/%name%.%formatOUT%"
ECHO.

:: Moving the output back to the original folder
IF EXIST "%tmpPath%\*.%formatOUT%" (
    FOR %%x IN ("%tmpPath%\*.%formatOUT%") DO IF NOT %%~zx==0 (
        ECHO %_fBRed%^>^>%_fGreen% File exists, size is non zero %_RESET%
        CALL :MoveBack
		ECHO %_fBRed%^>^>%_fGreen% Done %_RESET%
		CALL :Cleanup
    ) ELSE (
        ECHO %_fBRed%^>^>%_fGreen% File is zero bites. Compressing didn't work. %_RESET%
		CALL :Fail
    )
) ELSE (
    ECHO %_fBRed%^>^>%_fGreen% Failed compression. %_RESET%
	CALL :Fail
)
CALL :Cleanup
ECHO %_fBRed%^>^>%_fGreen% Ended compression %_RESET%
GOTO:eof

:Startup
Set _fGreen=[32m
Set _fBRed=[91m
Set _RESET=[0m
CALL :upper %formatIN% formatINupper
CALL :upper %formatOUT% formatOUTupper
GOTO:eof

:SetOriginalFolder
:: Need to re-add the current folder in case we gave the script a folder without root path
SET "originalFolder=%~dp1"
ECHO %originalFolder%
:: This second SET removes the trailing \ that upsets ROBOCOPY
SET "originalFolder=%originalFolder:~0, -1%"
GOTO:eof

:CreateTemp
ECHO %_fBRed%^>^>%_fGreen% Creating temp folder %_RESET%
IF EXIST "%~1" CMD /C RD /S /Q "%~1"
MKDIR "%~1"
GOTO:eof


:MoveBack
ECHO %_fBRed%^>^>%_fGreen% Moving %formatOUTupper% file back to position. %_RESET%
ROBOCOPY "%tmpPath%" "%originalFolder%" "*.%formatOUT%" /MOVE /MT:16 /COMPRESS
GOTO:eof


:Cleanup
ECHO.
ECHO %_fBRed%^>^>%_fGreen% Cleaning up... %_RESET%
IF {%DeleteSourceOnSuccess%}=={1} DEL /Q /F "%originalFolder%\%file%"
CMD /C RD /S /Q "%tmpPath%"
GOTO:eof


:Fail
ECHO.
ECHO %_fBRed%^>^>%_fGreen% FAILED
CALL :Cleanup
GOTO:eof


:upper
SET "%2=%1"
FOR %%a IN (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO CALL SET "%2=%%%2:%%a=%%a%%%"
GOTO:eof


:: Help and End
:Help
ECHO Try running this on a folder with %formatIN% files
ECHO or using one of the following syntaxes:
ECHO [script] [folder]
ECHO [script] [file.%formatIN%]
ECHO The script will not work if there are no %formatIN% files.
ECHO.
GOTO :End

:End
ENDLOCAL
EXIT /B