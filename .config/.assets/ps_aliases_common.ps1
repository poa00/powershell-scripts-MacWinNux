# *Functions
function .. { Set-Location ../ }
function ... { Set-Location ../../ }
function .... { Set-Location ../../../ }
function src { . $PROFILE.CurrentUserAllHosts }
function la { Get-ChildItem @args -Force }

# *Aliases
Set-Alias -Name c -Value Clear-Host
Set-Alias -Name type -Value Get-Command
