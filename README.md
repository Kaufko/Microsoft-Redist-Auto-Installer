# Microsoft-Redist-Auto-Installer
System-wide microsoft redist installer (vc++ x86 x64 DirectX and .NET)

## Usage
### open powershell as admin
```Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; 
Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Kaufko/Microsoft-Redist-Auto-Installer/master/Redistrubutable%20installer.ps1").Content
```
