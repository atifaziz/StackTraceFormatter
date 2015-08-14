@echo off
pushd "%~dp0"
PowerShell -C "(type StackTraceFormatter.cs) -replace 'namespace\s+[a-z]+', 'namespace $rootnamespace$' | Out-File -Encoding ascii StackTraceFormatter.cs.pp" ^
 && call build ^
 && nuget pack StackTraceFormatter.Source.nuspec
popd
