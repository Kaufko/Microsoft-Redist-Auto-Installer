if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $argString = $args -join ' '
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`" $argString" -Verb RunAs
    exit
}



#region Functions
    function Start-Installation {
        if($vc86toggle.Checked)
        {
            Install-VC86
        }
        if($vc64toggle.Checked)
        {
            Install-VC64
        }
        if($directXtoggle.Checked)
        {
            Install-DirectX
        }
        if($dotnettoggle.Checked)
        {
            Install-Dotnet
        }
    }
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
function Install-VC86 {
    Write-Output "Downloading VC++ x86"
    Invoke-RestMethod -Uri "https://aka.ms/vs/17/release/vc_redist.x86.exe" -OutFile "$downloadLocation\vc_redist.x86.exe"

    Write-Host "Installing Visual Studio C++ x86"
    $vcRedistLog = "vc86.log"
    $process = Start-Process "$downloadLocation\vc_redist.x86.exe" -ArgumentList "/install", "/passive", "/norestart", "/log `"$downloadLocation\$vcRedistLog`"" -Wait -PassThru
    if ($process.ExitCode -eq 0) {
        Write-Host "Installation succeeded." -ForegroundColor Green
    } elseif ($process.ExitCode -eq 3010) {
        Write-Host "Installation succeeded, but a reboot is required." -ForegroundColor DarkYellow
    } else {
        Write-Host "Installation failed with exit code $($process.ExitCode)." -ForegroundColor Red
        Get-Content "$downloadLocation\$vcRedistLog"
    }
    Remove-Item "$downloadLocation\$vcRedistLog"
    Remove-Item -Path "$downloadLocation\vc_redist.x86.exe" -Force -ErrorAction SilentlyContinue
    Write-Host ""
}
function Install-VC64 {
    Write-Output "Downloading VC++ x64"
    Invoke-RestMethod -Uri "https://aka.ms/vs/17/release/vc_redist.x64.exe" -OutFile "$downloadLocation\vc_redist.x64.exe"

    Write-Host "Installing Visual Studio C++ x64"
    $vcRedistLog = "vc64.log"
    $process = Start-Process "$downloadLocation\vc_redist.x64.exe" -ArgumentList "/install", "/passive", "/norestart", "/log `"$downloadLocation\$vcRedistLog`"" -Wait -PassThru
    if ($process.ExitCode -eq 0) {
        Write-Host "Installation succeeded." -ForegroundColor Green
    } elseif ($process.ExitCode -eq 3010) {
        Write-Host "Installation succeeded, but a reboot is required." -ForegroundColor DarkYellow
    } else {
        Write-Host "Installation failed with exit code $($process.ExitCode)." -ForegroundColor Red
        Get-Content "$downloadLocation\$vcRedistLog" 
    }
    Remove-Item "$downloadLocation\$vcRedistLog"
    Remove-Item -Path "$downloadLocation\vc_redist.x64.exe" -Force -ErrorAction SilentlyContinue
    Write-Host ""
}
function Install-Dotnet {
    Write-Output "Getting latest stable .NET installer"
    $dotnetInstallerUrl = Get-LatestDotnet
    if($dotnetInstallerUrl -eq '')
    {
        Write-Host "Couldn't retrieve latest dotnet"
        break
    }
    Write-Output "Got: $dotnetInstallerUrl"
    Write-Output "Downloading .NET 9"
    Invoke-RestMethod -Uri "$dotnetInstallerUrl" -OutFile "$downloadLocation\dotnet9.exe"

    Write-Host "Installing Dotnet 9.0"
    $dotnetLog = "dotnet9.log"
    $process = Start-Process "$downloadLocation\dotnet9.exe" -ArgumentList "/install", "/passive", "/norestart", "/log `"$downloadLocation\$dotnetLog`"" -Wait -PassThru
    if ($process.ExitCode -eq 0) { 
        Write-Host "Installation succeeded." -ForegroundColor Green
    } elseif ($process.ExitCode -eq 3010) {
        Write-Host "Installation succeeded, but a reboot is required." -ForegroundColor DarkYellow
    } else {
        Write-Host "Installation failed with exit code $($process.ExitCode)." -ForegroundColor Red
        Get-Content "$downloadLocation\$dotnetLog"
    }
    Remove-Item "$downloadLocation\$dotnetLog"
    Remove-Item -Path "$downloadLocation\dotnet9.exe" -Force -ErrorAction SilentlyContinue
    Write-Host ""
}
function Install-DirectX {
    Write-Output "Downloading DirectX"
    Invoke-RestMethod -Uri "https://download.microsoft.com/download/1/7/1/1718ccc4-6315-4d8e-9543-8e28a4e18c4c/dxwebsetup.exe" -OutFile "$downloadLocation\dxwebsetup.exe"
    Write-Host "Installing DirectX"
    $directXlog = "dxwebsetup.log"
    $process = Start-Process "$downloadLocation\dxwebsetup.exe" -ArgumentList "/Q" -Wait -PassThru
    if ($process.ExitCode -eq 0) {
        Write-Host "Installation succeeded." -ForegroundColor Green
    } elseif ($process.ExitCode -eq 3010) {
        Write-Host "Installation succeeded, but a reboot is required." -ForegroundColor DarkYellow
    } else {
        Write-Host "Installation failed with exit code $($process.ExitCode)." -ForegroundColor Red
    }
    Remove-Item "$downloadLocation\$directXlog" -ErrorAction SilentlyContinue
    Remove-Item -Path "$downloadLocation\dxwebsetup.exe" -Force -ErrorAction SilentlyContinue
    Write-Host ""
}

if($args[0] -eq "/H")
{
    Install-VC86
    Install-VC64
    Install-DirectX
    Install-Dotnet
}
else
{
    Add-Type -AssemblyName System.Windows.Forms

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Redist installer"
    $form.Size = New-Object System.Drawing.Size(600,400)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.BackColor = [System.Drawing.Color]::DarkSlateBlue
    $form.ForeColor = [System.Drawing.Color]::Snow

    $flowPanel = New-Object System.Windows.Forms.FlowLayoutPanel
    $flowPanel.Dock = [System.Windows.Forms.DockStyle]::Top
    $flowPanel.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
    $flowPanel.WrapContents = $false
    $flowPanel.AutoSize = $true
    $flowPanel.Padding = [System.Windows.Forms.Padding]::new(10)

    $vc86toggle = New-Object System.Windows.Forms.CheckBox
    $vc86toggle.Text = "Visual C++ 86"

    $vc64toggle = New-Object System.Windows.Forms.CheckBox
    $vc64toggle.Text = "Visual C++ 64"

    $directXtoggle = New-Object System.Windows.Forms.CheckBox
    $directXtoggle.Text = "DirectX"

    $dotnettoggle = New-Object System.Windows.Forms.CheckBox
    $dotnettoggle.Text = ".NET Runtime"

    $startButton = New-Object System.Windows.Forms.Button
    $startButton.Text = "Start Installation"
    $startButton.Add_Click({ Start-Installation })
    $startButton.Size = New-Object System.Drawing.Size(120,20)

    $flowPanel.Controls.Add($vc86toggle)
    $flowPanel.Controls.Add($vc64toggle)
    $flowPanel.Controls.Add($directXtoggle)
    $flowPanel.Controls.Add($dotnettoggle)
    $flowPanel.Controls.Add($startButton)

    $form.Controls.Add($flowPanel)

    $form.Add_Shown({$form.Activate()})
    [void]$form.ShowDialog()
}

