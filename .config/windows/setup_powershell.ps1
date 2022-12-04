#Requires -PSEdition Desktop
<#
.SYNOPSIS
Script synopsis.
.EXAMPLE
$PromptFonts = 'powerline'
.config/windows/setup_powershell.ps1
.config/windows/setup_powershell.ps1 -PromptFonts 'powerline'
#>
[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [ValidateSet('standard', 'powerline')]
    [string]$PromptFonts = 'standard'
)
# source common functions
. .include/ps_functions.ps1

# *Install oh-my-posh
.config/windows/scripts/install_omp.ps1

# *Install PowerShell
.config/windows/scripts/install_pwsh.ps1

# *Setup profile
Update-SessionEnvironment
.config/windows/scripts/setup_profile.ps1

# *Copy assets
# calculate variables
$ompProfile = switch ($PromptFonts) {
    'standard' { '.config/.assets/theme.omp.json' }
    'powerline' { '.config/.assets/theme-pl.omp.json' }
}
$profilePath = pwsh.exe -NoProfile -Command '[IO.Path]::GetDirectoryName($PROFILE.CurrentUserAllHosts)'
$scriptsPath = [IO.Path]::Combine($profilePath, 'Scripts')

# oh-my-posh theme
Copy-Item -Path $ompProfile -Destination ([IO.Path]::Combine($profilePath, 'theme.omp.json'))
# PowerShell profile
Copy-Item -Path .config/.assets/profile.ps1 -Destination $profilePath
# PowerShell functions
New-Item $scriptsPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path .config/.assets/ps_aliases_common.ps1 -Destination $scriptsPath
# git functions
if (Get-Command git.exe -CommandType Application -ErrorAction SilentlyContinue) {
    Copy-Item -Path .config/.assets/ps_aliases_git.ps1 -Destination $scriptsPath
}
# kubectl functions
if (Get-Command kubectl.exe -CommandType Application -ErrorAction SilentlyContinue) {
    Copy-Item -Path .config/.assets/ps_aliases_kubectl.ps1 -Destination $scriptsPath
    # add powershell kubectl autocompletion
    pwsh.exe -NoProfile -Command '(kubectl completion powershell).Replace("''kubectl''", "''k''") > $PROFILE'
}
