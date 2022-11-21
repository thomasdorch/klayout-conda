setlocal EnableDelayedExpansion

set CONFIG=release
set HAVE_QTBINDINGS=1
set HAVE_QT=1
set HAVE_64BIT_COORD=0
set HAVE_PYTHON=1
set HAVE_RUBY=1
set MAKE_OPT=
set HAVE_CURL=0
set HAVE_EXPAT=0
set HAVE_PTHREADS=0

set "p=/"
set "r=\"

for /f "tokens=*" %%i in ('python -c "import sysconfig; print(sysconfig.get_config_var('VERSION'))"') do (
	set "PYVER=%%i"
)
for /f "tokens=*" %%i in ('python -c "import sysconfig; print(sysconfig.get_config_var('installed_base'))"') do (
	set "d=%%i"
	set "PYBASE=!d:%p%=%r%!"
)
for /f "tokens=*" %%i in ('python -c "import sysconfig; print(sysconfig.get_config_var('INCLUDEPY'))"') do (
	set "d=%%i"
	set "PYTHONINCLUDE=!d:%p%=%r%!"
)
for /f "tokens=*" %%i in ('python -c "import sysconfig; print(sysconfig.get_config_var('EXT_SUFFIX'))"') do (
	set "PYTHONEXTSUFFIX=%%i"
)

set "PYTHONLIBFILE=%PYBASE%\libs\python%PYVER%.lib"


echo "    Python installation is in:"
echo "    - %PYTHONLIBFILE% 		(lib)"
echo "    - %PYTHONINCLUDE% 		(includes)"
echo "    - %PYTHONEXTSUFFIX% 	(ext. suffix)"
echo ""


for /f "tokens=*" %%i in ('ruby -rrbconfig -e "puts (RbConfig::CONFIG['rubyhdrdir'] || '')"') do (
	set "d=%%i"
	set "RUBYINCLUDE=!d:%p%=%r%!"
)
for /f "tokens=*" %%i in ('ruby -rrbconfig -e "puts (RbConfig::CONFIG['rubyarchhdrdir'] || '')"') do (
	set "d=%%i"
	set "RUBYINCLUDE2=!d:%p%=%r%!"
)
for /f "tokens=*" %%i in ('ruby -rrbconfig -e "puts (RbConfig::CONFIG['MAJOR'] || 0).to_i*10000+(RbConfig::CONFIG['MINOR'] || 0).to_i*100+(RbConfig::CONFIG['TEENY'] || 0).to_i"') do (
	set "RUBYVERSIONCODE=%%i"
)
for /f "tokens=*" %%i in ('ruby -rrbconfig -e "puts (RbConfig::CONFIG['LIBRUBY'] || '')"') do (
	set "RUBYLIBFILENAME=%%i"
)
for /f "tokens=*" %%i in ('ruby -rrbconfig -e "puts (RbConfig::CONFIG['libdir'] || '')"') do (
	set "d=%%i"
	set "RUBYLIBFILEPATH=!d:%p%=%r%!"
)
set RUBYLIBFILE=%RUBYLIBFILEPATH%\%RUBYLIBFILENAME%

echo "    Ruby installation is in:"
echo "    - %RUBYLIBFILE% "
echo "    - %RUBYINCLUDE% (headers)"
echo "    - %RUBYINCLUDE2% (arch headers)"
echo "    Ruby version code is %RUBYVERSIONCODE%"
echo ""

set QMAKE_LIBS=%LIBRARY_LIBS%\zlib.lib %RUBYLIBFILE% %PYTHONLIBFILE%

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

echo KLAYOUT_VERSION:		%KLAYOUT_VERSION%
echo KLAYOUT_VERSION_DATE:	%KLAYOUT_VERSION_DATE%
echo KLAYOUT_VERSION_REV:	%KLAYOUT_VERSION_REV%


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
  "PREFIX=%LIBRARY_BIN%" ^
  %SRC_DIR%\klayout\src\klayout.pro || exit /b 1 

echo #### QMake Completed ####

jom

echo #### NMake Completed ####

jom install

echo #### NMake Install Completed ####

move %LIBRARY_BIN%\pymod\pya %SP_DIR%\pya
move %LIBRARY_BIN%\pymod\klayout %SP_DIR%\klayout