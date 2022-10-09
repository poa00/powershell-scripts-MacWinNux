# *Functions
function .. { Set-Location ../ }
function ... { Set-Location ../../ }
function .... { Set-Location ../../../ }
function src { . $PROFILE.CurrentUserAllHosts }
function la {
    $arguments = $args.ForEach({ $_ -match ' ' ? "'$_'" : $_ })
    Invoke-Expression "Get-ChildItem $arguments -Force"
}
function Get-CmdAlias ([string]$CmdletName) {
    Get-Alias | `
        Where-Object -FilterScript { $_.Definition -match $CmdletName } | `
        Sort-Object -Property Definition, Name | `
        Select-Object -Property Definition, Name
}

# *Aliases
Set-Alias -Name alias -Value Get-CmdAlias
Set-Alias -Name c -Value Clear-Host
Set-Alias -Name type -Value Get-Command
