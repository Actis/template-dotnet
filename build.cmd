@echo off

setlocal enableextensions enabledelayedexpansion
set EnableNuGetPackageRestore=true

pushd %~dp0

call :FindMSBuild16 || call :FindMSBuild15 || call :FindMSBuild 14 12 4 || (
	echo Could not find any applicable MSBuild version
	exit /b !ERRORLEVEL!
)

if defined _BUILD_CMD_DEBUG echo Using MSBuild version %MSBUILDVER% from "%MSBUILDDIR%"

if %MSBUILDVER% lss 15 (
	call :ResolveNuGet NuGet.exe || exit /b !ERRORLEVEL!

	if defined _BUILD_CMD_DEBUG echo Found NuGet at "%NuGetExe%"

	if exist .nuget\packages.config (
		echo Restoring packages from !CD!\.nuget\packages.config
		"!NuGetExe!" restore .nuget\packages.config -MSBuildPath "%MSBUILDDIR%" -OutputDirectory packages -NonInteractive -Verbosity quiet || exit /b !ERRORLEVEL!
	)

	if exist *.sln for %%F in (*.sln) do (
		echo Restoring packages from %%~fF
		"!NuGetExe!" restore "%%F" -MSBuildPath "%MSBUILDDIR%" -NonInteractive -Verbosity quiet || exit /b !ERRORLEVEL!
	)

	::for /r src %%F in (packages.config) do if exist "%%F" if exist "%%~dpFwebsite.publishproj" (
	::	echo Restoring packages from %%F
	::	"!NuGetExe!" restore "%%F" -MSBuildPath "%MSBUILDDIR%" -SolutionDirectory . -NonInteractive -Verbosity quiet || exit /b !ERRORLEVEL!
	::)
)

"%MSBUILDDIR%\MSBuild.exe" build.proj /nologo /v:m %*

popd

if errorlevel 1 (
	echo Something went wrong while building. Check the output above. MSBuild exited with code %ERRORLEVEL%.
	exit /b %ERRORLEVEL%
)

goto :EOF

:ResolveNuGet filename
if exist "%CD%\.nuget\%1" (
	set NuGetExe=!CD!\.nuget\%1
	goto :EOF
)
set NuGetExe=%~$PATH:1
if not "%NuGetExe%"=="" goto :EOF
echo %1 was not found either in .nuget subfolder or PATH
exit /b 1

:: https://blogs.msdn.microsoft.com/heaths/2017/02/25/vswhere-available/
:FindMSBuild16
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
	set "_vswhere_=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"
) else (
	set "_vswhere_=%ProgramFiles%\Microsoft Visual Studio\Installer"
)
if exist "%_vswhere_%\vswhere.exe" (
	pushd "%_vswhere_%"
	for /f "usebackq tokens=*" %%A in (`vswhere.exe -latest -products * -requires Microsoft.Component.MSBuild -version "[16,17)" -property installationPath`) do (
		if exist "%%A\MSBuild\Current\Bin\MSBuild.exe" (
			set MSBUILDDIR=%%A\MSBuild\Current\Bin
			if "%PROCESSOR_ARCHITECTURE%"=="AMD64" set MSBUILDDIR=!MSBUILDDIR!\amd64
			set MSBUILDVER=16
			popd
			set _vswhere_=
			goto :EOF
		)
	)
	popd
)
set _vswhere_=
exit /b 1

:FindMSBuild15
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
	set "_vswhere_=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"
) else (
	set "_vswhere_=%ProgramFiles%\Microsoft Visual Studio\Installer"
)
if exist "%_vswhere_%\vswhere.exe" (
	pushd "%_vswhere_%"
	for /f "usebackq tokens=*" %%A in (`vswhere.exe -latest -products * -requires Microsoft.Component.MSBuild -version "[15.0,16.0)" -property installationPath`) do (
		if exist "%%A\MSBuild\15.0\Bin\MSBuild.exe" (
			set MSBUILDDIR=%%A\MSBuild\15.0\Bin
			if "%PROCESSOR_ARCHITECTURE%"=="AMD64" set MSBUILDDIR=!MSBUILDDIR!\amd64
			set MSBUILDVER=15
			popd
			set _vswhere_=
			goto :EOF
		)
	)
	popd
)
set _vswhere_=
exit /b 1

:: http://stackoverflow.com/a/20431996/393672
:FindMSBuild v1 ... vN
if "%1"=="" exit /b 1
reg.exe query "HKLM\SOFTWARE\Microsoft\MSBuild\ToolsVersions\%1.0" /v MSBuildToolsPath > nul 2>&1
if not errorlevel 1 (
	for /f "skip=2 tokens=2,*" %%A in ('reg.exe query "HKLM\SOFTWARE\Microsoft\MSBuild\ToolsVersions\%1.0" /v MSBuildToolsPath') do (
		if exist "%%BMSBuild.exe" (
			set MSBUILDDIR=%%B
			set MSBUILDDIR=!MSBUILDDIR:~0,-1!
			set MSBUILDVER=%1
			goto :EOF
		)
	)
)
shift
goto :FindMSBuild
