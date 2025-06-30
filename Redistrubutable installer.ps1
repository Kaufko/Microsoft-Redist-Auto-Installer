$bAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

If ($bAdmin -eq $False) {
    Write-Host "No administrator permissions! Relaunch as admin, otherwise redistributables will fail to install"
    Timeout 5
    Exit
}

#region Functions
    function Get-LatestDotnet {
    $response = Invoke-WebRequest -Uri "https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/releases-index.json"
    $data = $response.Content | ConvertFrom-Json
    $releasesIndex = $data.'releases-index'

    foreach ($releaseIndex in $releasesIndex) {
        $latestRelease = $releaseIndex.'latest-release'
        if ($latestRelease) {
            $latestReleaseSplit = $latestRelease.Split('-')
            if($latestReleaseSplit.Length -le 1)
            {
                $data = Invoke-WebRequest -Uri $releaseIndex.'releases.json'
                
                $versionReleases = $data.Content | ConvertFrom-Json
                $versionFiles = $versionReleases.'releases'.'windowsdesktop'.'files'
                $arch = $env:PROCESSOR_ARCHITECTURE
                if ($arch -eq "AMD64") {
                    $arch = 'win-x64'
                } elseif ($arch -eq "ARM64") {
                    $arch = 'arm-x64'
                } elseif ($arch -eq "AMD86") {
                    $arch = 'win-x86'
                } else
                {
                    Write-Host "INVALID OS"
                    return ''
                }
                foreach ($versionFile in $versionFiles)
                {
                    if($versionFile.'rid' -eq $arch)
                    {
                        return $versionFile.'url'
                    }
                }
                break
            }
        }
    }
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
