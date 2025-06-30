# Microsoft-Redist-Auto-Installer
System-wide microsoft redist installer (vc++ x86 x64 DirectX and .NET)
Automatically gets the latest stable DotNet version (as of 30.06.2025 that is 9.0.6)
DirectX 
## Usage
### open powershell as admin
```Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; 
Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Kaufko/Microsoft-Redist-Auto-Installer/master/Redistrubutable%20installer.ps1").Content
```
