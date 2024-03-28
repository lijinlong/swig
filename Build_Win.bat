
rem You must have cmake and 7zip installed
rem Download dependencies
set WIN_FLEX_BISON_URL=https://jaist.dl.sourceforge.net/project/winflexbison/win_flex_bison3-latest.zip
set PCRE2_URL=https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.39/pcre2-10.39.zip
if NOT EXIST External\win_flex_bison\win_flex.exe (
    mkdir External
    echo Download win_flex_bison from %WIN_FLEX_BISON_URL%
    powershell -Command "Invoke-WebRequest %WIN_FLEX_BISON_URL% -OutFile External\win_flex_bison.zip"
    echo Extract to External
    powershell -Command "Expand-Archive -Path External\win_flex_bison.zip -DestinationPath External\win_flex_bison"
    del /Q External\win_flex_bison.zip > NUL

    echo Download pcre2-10.39 from %PCRE2_URL%
    powershell -Command "Invoke-WebRequest %PCRE2_URL% -OutFile External\pcre2.zip"
    echo Extract to External
    powershell -Command "Expand-Archive -Path External\pcre2.zip -DestinationPath External"
    del /Q External\pcre2.zip > NUL
)

if NOT EXIST External\pcre2-10.39\build\Release\pcre2-8-static.lib (
    rem make pcre2 lib
    pushd External\pcre2-10.39
    cmake -B build -S .
    cmake --build build --config Release
    popd
)

rem Setup env
path=%~dp0\External\win_flex_bison;%path%
set PCRE_ROOT=%~dp0\External\pcre2-10.39
set PCRE_PLATFORM="x64"

rem make
cmake -G "Visual Studio 16 2019" -A "x64" -DCMAKE_C_FLAGS="/DPCRE2_STATIC" -DCMAKE_CXX_FLAGS="/DPCRE2_STATIC" -DPCRE2_INCLUDE_DIR="%PCRE_ROOT%/build" -DPCRE2_LIBRARY="%PCRE_ROOT%/build/Release/pcre2-8-static.lib" -S . -B build
cmake --build build --config Release

xcopy /S /Q Examples\* build\Release\Examples\
xcopy /S /Q Lib\* build\Release\Lib\
copy build\swigwarn.swg build\Release\Lib\

rem package
pushd build\Release
7z a swig.zip swig.exe Examples\* Lib\*
popd

rem calling
rem swig -c++ -csharp -outdir ex\csharp ex\example.i
rem swig -c++ -cs_il2cpp -outdir ex\il2cpp ex\example.i