#!/usr/bin/env -S pwsh -nop
<#
.SYNOPSIS
Setting up PowerShell for the current user.
.EXAMPLE
scripts/linux/.include/setup_profile_user.ps1
#>
$ErrorActionPreference = 'SilentlyContinue'
$WarningPreference = 'Ignore'

# *PowerShell profile
if (Get-InstalledModule -Name PowerShellGet) {
    if (-not (Get-PSResourceRepository -Name PSGallery).Trusted) {
        Write-Host 'setting PSGallery trusted...'
        Set-PSResourceRepository -Name PSGallery -Trusted
        # update help, assuming this is the initial setup
        Write-Host 'updating help...'
        Update-Help
    }
    # update existing modules
    if (Test-Path scripts/linux/.include/update_psresources.ps1 -PathType Leaf) {
        scripts/linux/.include/update_psresources.ps1
    }
}

if ((Test-Path /usr/bin/kubectl) -and -not (Select-String '__kubectl_debug' -Path $PROFILE -Quiet)) {
    Write-Host 'adding kubectl auto-completion...'
    $profileDir = [IO.Path]::GetDirectoryName($PROFILE)
    if (-not (Test-Path $profileDir -PathType Container)) {
        New-Item $profileDir -ItemType Directory | Out-Null
    }
    (/usr/bin/kubectl completion powershell).Replace("'kubectl'", "'k'") >$PROFILE
}

if ((Test-Path $HOME/miniconda3/bin/conda) -and -not (Select-String 'conda init' -Path $PROFILE.CurrentUserAllHosts -Quiet)) {
    Write-Verbose 'adding miniconda initialization...'
    & "$HOME/miniconda3/bin/conda" init powershell | Out-Null
}
