$bAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

If ($bAdmin -eq $False) {
    Write-Host "No administrator permissions! Relaunch as admin, otherwise redistributables will fail to install"
    Timeout 5
    Exit
}

#region Functions
    function Get-LatestDotnetRuntime {
        $versionList = Invoke-RestMethod -Uri "https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/releases-index.json"

        $latestStableChannel = $versionList.'releases-index' | 
            Where-Object { $_.'support-phase' -eq 'active' -and $_.'channel-version' -notlike '*-preview*' } |
            Sort-Object { [version]$_.'channel-version' } -Descending |
            Select-Object -First 1

        $channelResponse = Invoke-RestMethod -Uri $latestStableChannel.'releases.json'

        function ConvertTo-SortableVersion {
            param($versionString)
            $baseVersion = $versionString -replace '-.*$'
            try {
                [version]$baseVersion
            }
            catch {
                [version]"0.0.0"
            }
        }

        $latestRelease = $channelResponse.releases | 
            Where-Object { $_.'runtime'.version -notmatch 'preview|rc' } |
            Sort-Object { ConvertTo-SortableVersion $_.'runtime'.version } -Descending |
            Select-Object -First 1

        # Get the download URL for Windows x64 runtime
        $downloadUrl = ($latestRelease.runtime.files | Where-Object {
            $_.name -eq 'dotnet-runtime-win-x64.exe' -or 
            $_.name -like 'dotnet-runtime-*-win-x64.exe'
        }).url

        return $downloadUrl
    }
#endregion



$ProgressPreference = 'SilentlyContinue' #turns off update bar (speeds up downloads by 90%)
$downloadLocation = $env:TEMP

Write-Output "Downloading VC++ x64"
Invoke-RestMethod -Uri "https://aka.ms/vs/17/release/vc_redist.x64.exe" -OutFile "$downloadLocation\vc_redist.x64.exe"
Write-Output "Downloading VC++ x86"
Invoke-RestMethod -Uri "https://aka.ms/vs/17/release/vc_redist.x86.exe" -OutFile "$downloadLocation\vc_redist.x86.exe"
Write-Output "Getting latest stable .NET installer"
$dotnetInstallerUrl = Get-LatestDotnet
Write-Output "Got: $dotnetInstallerUrl"
Write-Output "Downloading .NET 9"
Invoke-RestMethod -Uri "$dotnetInstallerUrl" -OutFile "$downloadLocation\dotnet9.exe"
Write-Output "Downloading DirectX"
Invoke-RestMethod -Uri "https://download.microsoft.com/download/1/7/1/1718ccc4-6315-4d8e-9543-8e28a4e18c4c/dxwebsetup.exe" -OutFile "$downloadLocation\dxwebsetup.exe"

Write-Host "Installing Visual Studio C++ x64"
$vcRedistLog = "vc64.log"
$process = Start-Process "$downloadLocation\vc_redist.x64.exe" -ArgumentList "/install", "/passive", "/norestart", "/log `"$downloadLocation\$vcRedistLog`"" -Wait -PassThru
if ($process.ExitCode -eq 0) {
    Write-Host "Installation succeeded."
} elseif ($process.ExitCode -eq 3010) {
    Write-Host "Installation succeeded, but a reboot is required."
} else {
    Write-Host "Installation failed with exit code $($process.ExitCode)."
    Get-Content "$downloadLocation\$vcRedistLog"
}
Remove-Item "$downloadLocation\$vcRedistLog"

Write-Host "Installing Visual Studio C++ x86"
$vcRedistLog = "vc86.log"
$process = Start-Process "$downloadLocation\vc_redist.x86.exe" -ArgumentList "/install", "/passive", "/norestart", "/log `"$downloadLocation\$vcRedistLog`"" -Wait -PassThru
if ($process.ExitCode -eq 0) {
    Write-Host "Installation succeeded."
} elseif ($process.ExitCode -eq 3010) {
    Write-Host "Installation succeeded, but a reboot is required."
} else {
    Write-Host "Installation failed with exit code $($process.ExitCode)."
    Get-Content "$downloadLocation\$vcRedistLog"
}
Remove-Item "$downloadLocation\$vcRedistLog"

Write-Host "Installing Dotnet 9.0"
$dotnetLog = "dotnet9.log"
$process = Start-Process "$downloadLocation\dotnet9.exe" -ArgumentList "/install", "/passive", "/norestart", "/log `"$downloadLocation\$dotnetLog`"" -Wait -PassThru
if ($process.ExitCode -eq 0) {
    Write-Host "Installation succeeded."
} elseif ($process.ExitCode -eq 3010) {
    Write-Host "Installation succeeded, but a reboot is required."
} else {
    Write-Host "Installation failed with exit code $($process.ExitCode)."
    Get-Content "$downloadLocation\$dotnetLog"
}
Remove-Item "$downloadLocation\$dotnetLog"

Write-Host "Installing DirectX"
$directXlog = "dxwebsetup.log"
$process = Start-Process "$downloadLocation\dxwebsetup.exe" -ArgumentList "/Q" -Wait -PassThru
if ($process.ExitCode -eq 0) {
    Write-Host "Installation succeeded."
} elseif ($process.ExitCode -eq 3010) {
    Write-Host "Installation succeeded, but a reboot is required."
} else {
    Write-Host "Installation failed with exit code $($process.ExitCode)."
}
Remove-Item "$downloadLocation\$directXlog" -ErrorAction SilentlyContinue

Remove-Item -Path "$downloadLocation\vc_redist.x64.exe" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$downloadLocation\vc_redist.x86.exe" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$downloadLocation\dotnet9.exe" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$downloadLocation\dxwebsetup.exe" -Force -ErrorAction SilentlyContinue
