# Microsoft-Redist-Auto-Installer
System-wide microsoft redist installer (vc++ x86 x64 DirectX and .NET)
Automatically gets the latest stable DotNet version (as of 30.06.2025 that is 9.0.6)
DirectX 
## Usage
### open powershell as admin
#### Non-UI version
```
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; 
Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Kaufko/Microsoft-Redist-Auto-Installer/master/Redistrubutable%20installer.ps1").Content
```
####  UI version
```
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass;
Invoke-Expression (Invoke-WebRequest -Uri "https://https://raw.githubusercontent.com/Kaufko/Microsoft-Redist-Auto-Installer/blob/master/Redistrubutable%20installer%20GUI.ps1").Content
```
All download external links and files are only from Microsoft official servers.
