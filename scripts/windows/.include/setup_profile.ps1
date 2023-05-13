#Requires -Version 7.0
<#
.SYNOPSIS
Set up PowerShell Core profile on Windows.

.PARAMETER OmpTheme
Specify oh-my-posh theme to be installed, from themes available on the page.
There are also two baseline profiles included: base and powerline.
.PARAMETER PSModules
List of PowerShell modules from ps-modules repository to be installed.
.PARAMETER UpdateModules
Switch, whether to update installed PowerShell modules.

.EXAMPLE
$PSModules = @('do-common', 'do-win')
# ~set up PowerShell without oh-my-posh
scripts/windows/.include/setup_profile.ps1
scripts/windows/.include/setup_profile.ps1 -m $PSModules
scripts/windows/.include/setup_profile.ps1 -m $PSModules -UpdateModules
# ~set up PowerShell with oh-my-posh
$OmpTheme = 'powerline'
scripts/windows/.include/setup_profile.ps1 -t $OmpTheme
scripts/windows/.include/setup_profile.ps1 -t $OmpTheme -m $PSModules
scripts/windows/.include/setup_profile.ps1 -t $OmpTheme -m $PSModules -UpdateModules
#>
[CmdletBinding()]
param (
    [Alias('t')]
    [string]$OmpTheme,

    [Alias('m')]
    [string[]]$PSModules,

    [switch]$UpdateModules
)

begin {
    $ErrorActionPreference = 'Stop'

    # calculate variables
    $profilePath = [IO.Path]::GetDirectoryName($PROFILE)
    $scriptsPath = [IO.Path]::Combine($profilePath, 'Scripts')

    # create profile path if not exist
    if (-not (Test-Path $profilePath -PathType Container)) {
        New-Item $profilePath -ItemType Directory | Out-Null
    }

    # set location to workspace folder
    Push-Location "$PSScriptRoot/../../.."
}

process {
    # *PowerShell profile
    if ($OmpTheme) {
        Write-Host 'installing omp...' -ForegroundColor Cyan
        scripts/windows/.include/install_omp.ps1
        scripts/windows/.include/setup_omp.ps1 $OmpTheme
        Copy-Item -Path .config/pwsh_cfg/profile.ps1 -Destination $PROFILE.CurrentUserAllHosts -Force
    } else {
        Copy-Item -Path .config/pwsh_cfg/profile_win.ps1 -Destination $PROFILE.CurrentUserAllHosts -Force
    }

    # *PowerShell functions
    Write-Host 'setting up profile...' -ForegroundColor Cyan
    # TODO to be removed, cleanup legacy aliases
    if (-not (Test-Path $scriptsPath)) {
        New-Item $scriptsPath -ItemType Directory | Out-Null
    }
    Get-ChildItem -Path $scriptsPath -Filter '*_aliases_*.ps1' -File | Remove-Item -Force
    if (-not (Test-Path $scriptsPath -PathType Container)) {
        New-Item $scriptsPath -ItemType Directory | Out-Null
    }
    Write-Host 'copying aliases' -ForegroundColor DarkGreen
    Copy-Item -Path .config/pwsh_cfg/_aliases_common.ps1 -Destination $scriptsPath -Force
    Copy-Item -Path .config/pwsh_cfg/_aliases_win.ps1 -Destination $scriptsPath -Force

    # *conda init
    $condaSet = try { Select-String 'conda init' -Path $PROFILE.CurrentUserAllHosts -Quiet } catch { $false }
    if ((Test-Path $HOME/miniconda3/Scripts/conda.exe) -and -not $condaSet) {
        Write-Verbose 'adding miniconda initialization...'
        & "$HOME/miniconda3/Scripts/conda.exe" init powershell | Out-Null
    }

    # *install modules
    $psGetVer = (Find-Module PowerShellGet -AllowPrerelease).Version
    for ($i = 0; $psGetVer -and ($psGetVer -notin (Get-InstalledModule -Name PowerShellGet -AllVersions).Version) -and $i -lt 10; $i++) {
        Write-Host 'installing PowerShellGet...'
        Install-Module PowerShellGet -AllowPrerelease -Force -SkipPublisherCheck
    }
    # install/update modules
    if (Get-InstalledModule -Name PowerShellGet) {
        if (-not (Get-PSResourceRepository -Name PSGallery).Trusted) {
            Write-Host 'setting PSGallery trusted...'
            Set-PSResourceRepository -Name PSGallery -Trusted
        }
        for ($i = 0; (Test-Path /usr/bin/git) -and -not (Get-Module posh-git -ListAvailable) -and $i -lt 10; $i++) {
            Write-Host 'installing posh-git...'
            Install-PSResource -Name posh-git
        }
        # update existing modules
        if (Test-Path scripts/windows/.include/update_psresources.ps1 -PathType Leaf) {
            scripts/windows/.include/update_psresources.ps1
        }
    }

    # *ps-modules
    $modules = @(
        $PSModules
        (Get-Module -ListAvailable Az) ? 'do-az' : $null
        (Get-Command git.exe -CommandType Application -ErrorAction SilentlyContinue) ? 'aliases-git' : $null
        (Get-Command kubectl.exe -CommandType Application -ErrorAction SilentlyContinue) ? 'aliases-kubectl' : $null
    ).Where({ $_ }) | Select-Object -Unique

    if ('aliases-kubectl' -in $modules) {
        # set powershell kubectl autocompletion
        [IO.File]::WriteAllText($PROFILE, (kubectl.exe completion powershell).Replace("''kubectl''", "''k''"))
    }
    if ($modules) {
        Write-Host 'installing ps-modules...' -ForegroundColor Cyan
        # determine if ps-modules repository exist and clone if necessary
        $getOrigin = { git config --get remote.origin.url }
        $remote = (Invoke-Command $getOrigin).Replace('powershell-scripts', 'ps-modules')
        try {
            Push-Location '../ps-modules'
            if ($(Invoke-Command $getOrigin) -eq $remote) {
                # pull ps-modules repository
                git reset --hard --quiet && git clean --force -d && git pull --quiet
            } else {
                $modules = @()
            }
            Pop-Location
        } catch {
            # clone ps-modules repository
            git clone $remote ../ps-modules
        }
        if ($modules) {
            Write-Host "$modules" -ForegroundColor DarkGreen
            $modules | ../ps-modules/module_manage.ps1 -CleanUp -Verbose -ErrorAction SilentlyContinue
        }
    }
}

end {
    Pop-Location
}
