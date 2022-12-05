setlocal EnableDelayedExpansion

set CONFIG=release
set "out_dir=%LIBRARY_BIN%"

set HAVE_QTBINDINGS=1
set HAVE_QT=1
set HAVE_64BIT_COORD=0
set HAVE_PYTHON=1
set HAVE_RUBY=1
set HAVE_CURL=0
set HAVE_EXPAT=0
set HAVE_PTHREADS=0

rem Get Python paths
for /f "tokens=*" %%i in ('python -c "import sysconfig; print(sysconfig.get_config_var('EXT_SUFFIX'))"') do (
	set "PYTHONEXTSUFFIX=%%i"
)
for /f "tokens=*" %%i in ('python -c "import sysconfig; print(sysconfig.get_config_var('VERSION'))"') do (
	set "PYTHONVERSION=%%i"
)
for /f "tokens=*" %%i in ('python -c "import sysconfig; print(sysconfig.get_config_var('INCLUDEPY'))"') do (
	set "PYTHONINCLUDE=%%i"
)
rem Make sure paths have the correct slashes
set "PYTHONINCLUDE=!PYTHONINCLUDE:/=\!"

set "PYTHONLIBFILE=%PREFIX%\libs\python%PYTHONVERSION%.lib"

echo "    Python installation is in:"
echo "    - %PYTHONLIBFILE% 		(lib)"
echo "    - %PYTHONINCLUDE% 		(includes)"
echo "    - %PYTHONEXTSUFFIX% 	(ext. suffix)"
echo ""


rem Get Ruby paths
for /f "tokens=*" %%i in ('ruby -rrbconfig -e "puts (RbConfig::CONFIG['MAJOR'] || 0).to_i*10000+(RbConfig::CONFIG['MINOR'] || 0).to_i*100+(RbConfig::CONFIG['TEENY'] || 0).to_i"') do (
	set "RUBYVERSIONCODE=%%i"
)
for /f "tokens=*" %%i in ('ruby -rrbconfig -e "puts (RbConfig::CONFIG['LIBRUBY'] || '')"') do (
	set "RUBYLIBFILENAME=%%i"
)
for /f "tokens=*" %%i in ('ruby -rrbconfig -e "puts (RbConfig::CONFIG['libdir'] || '')"') do (
	set "RUBYLIBFILEPATH=%%i"
)
for /f "tokens=*" %%i in ('ruby -rrbconfig -e "puts (RbConfig::CONFIG['rubyhdrdir'] || '')"') do (
	set "RUBYINCLUDE=%%i"
)
for /f "tokens=*" %%i in ('ruby -rrbconfig -e "puts (RbConfig::CONFIG['rubyarchhdrdir'] || '')"') do (
	set "RUBYINCLUDE2=%%i"
)
rem Make sure paths have the correct slashes
set "RUBYLIBFILEPATH=!RUBYLIBFILEPATH:/=\!"
set "RUBYINCLUDE2=!RUBYINCLUDE2:/=\!"
set "RUBYINCLUDE=!RUBYINCLUDE:/=\!"

set RUBYLIBFILE=%RUBYLIBFILEPATH%\%RUBYLIBFILENAME%

echo "    Ruby installation is in:"
echo "    - %RUBYLIBFILE% "
echo "    - %RUBYINCLUDE% (headers)"
echo "    - %RUBYINCLUDE2% (arch headers)"
echo "    Ruby version code is %RUBYVERSIONCODE%"
echo ""

rem Tell qmake to link zlib, Python, and Ruby libraries
set "QMAKE_LIBS=-lz %RUBYLIBFILE% %PYTHONLIBFILE%"

echo Adding extra libs:		%QMAKE_LIBS%

rem Get KLayout version info
set KLAYOUT_VERSION=%PKG_VERSION%

date /t >%TEMP%\klayout-build-tmp.txt
set /P KLAYOUT_VERSION_DATE=<%TEMP%\klayout-build-tmp.txt
del %TEMP%\klayout-build-tmp.txt

rem The short SHA hash of the commit
git rev-parse --short HEAD 2>nul >%TEMP%\klayout-build-tmp.txt
set /P KLAYOUT_VERSION_REV=<%TEMP%\klayout-build-tmp.txt
if ERRORLEVEL 1 (
	set "KLAYOUT_VERSION_REV=LatestSourcePackage"
)
del %TEMP%\klayout-build-tmp.txt

echo KLAYOUT_VERSION:		    %KLAYOUT_VERSION%
echo KLAYOUT_VERSION_DATE:	%KLAYOUT_VERSION_DATE%
echo KLAYOUT_VERSION_REV:	  %KLAYOUT_VERSION_REV%

qmake ^
  HAVE_QT5=1 ^
  HAVE_QT_UITOOLS=1 ^
  HAVE_QT_NETWORK=1 ^
  HAVE_QT_SQL=1 ^
  HAVE_QT_SVG=1 ^
  HAVE_QT_PRINTSUPPORT=1 ^
  HAVE_QT_MULTIMEDIA=1 ^
  HAVE_QT_DESIGNER=1 ^
  HAVE_QT_XML=1 ^
  -recursive ^
  -spec win32-msvc ^
  "CONFIG+=%CONFIG%" ^
  "KLAYOUT_VERSION=%KLAYOUT_VERSION%" ^
  "KLAYOUT_VERSION_DATE=%KLAYOUT_VERSION_DATE%" ^
  "KLAYOUT_VERSION_REV=%KLAYOUT_VERSION_REV%" ^
  "HAVE_QTBINDINGS=%HAVE_QTBINDINGS%" ^
  "HAVE_QT=%HAVE_QT%" ^
  "HAVE_EXPAT=%HAVE_EXPAT%" ^
  "HAVE_CURL=%HAVE_CURL%" ^
  "HAVE_PTHREADS=%HAVE_PTHREADS%" ^
  "HAVE_RUBY=%HAVE_RUBY%" ^
  "HAVE_PYTHON=%HAVE_PYTHON%" ^
  "HAVE_64BIT_COORD=%HAVE_64BIT_COORD%" ^
  "PYTHONLIBFILE=%PYTHONLIBFILE%" ^
  "PYTHONINCLUDE=%PYTHONINCLUDE%" ^
  "PYTHONEXTSUFFIX=%PYTHONEXTSUFFIX%" ^
  "RUBYVERSIONCODE=%RUBYVERSIONCODE%" ^
  "RUBYINCLUDE=%RUBYINCLUDE%" ^
  "RUBYINCLUDE2=%RUBYINCLUDE2%" ^
  "RUBYLIBFILE=%RUBYLIBFILE%" ^
  "QMAKE_LIBS=%QMAKE_LIBS%" ^
  "PREFIX=%out_dir%" ^
  %SRC_DIR%\klayout\src\klayout.pro || exit /b 1

rem Build with multi-threaded nmake (jom) and install
jom || exit /b 1
jom install || exit /b 1

rem Move python modules into standard location
move %out_dir%\pymod\pya %PREFIX%\lib\pya
move %out_dir%\pymod\klayout %PREFIX%\lib\klayout