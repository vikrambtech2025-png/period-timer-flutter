@echo off
setlocal
set ANDROID_HOME=C:\Users\VIKRAM\.config\opencode\tools\android-sdk
set JAVA_HOME=C:\Users\VIKRAM\.config\opencode\tools\jdk-17.0.2
set PATH=%JAVA_HOME%\bin;%ANDROID_HOME%\platform-tools;%PATH%
cd /d "%~dp0"
call flutter pub get
if errorlevel 1 goto :err
call flutter build apk --release
if errorlevel 1 goto :err
echo.
echo BUILD SUCCESSFUL
echo APK: build\app\outputs\flutter-apk\app-release.apk
goto :end
:err
echo BUILD FAILED
:end
pause