#!/bin/bash
: '
.config/linux/setup_powershell.sh     #* install basic oh-my-posh profile
.config/linux/setup_powershell.sh pl  #* install powerline oh-my-posh profile
'
if [[ $EUID -eq 0 ]]; then
  echo -e '\e[91mDo not run the script with sudo!\e[0m'
  exit 1
fi

# *Install oh-my-posh
sudo .config/linux/scripts/install_omp.sh

# *Install PowerShell
sudo .config/linux/scripts/install_pwsh.sh

# *Setup profile
.config/linux/scripts/setup_profile.sh

# *Copy assets
# calculate variables
if [[ "$1" = 'pl' ]]; then
  OMP_THEME='.config/.assets/theme-pl.omp.json'
else
  OMP_THEME='.config/.assets/theme.omp.json'
fi
PS_PROFILE_PATH=$(pwsh -nop -c '[IO.Path]::GetDirectoryName($PROFILE.AllUsersAllHosts)')
PS_SCRIPTS_PATH='/usr/local/share/powershell/Scripts'
OH_MY_POSH_PATH='/usr/local/share/oh-my-posh'

# oh-my-posh theme
sudo \mkdir -p $OH_MY_POSH_PATH
sudo \cp -f $OMP_THEME "$OH_MY_POSH_PATH/theme.omp.json"
# PowerShell profile
sudo \cp -f .config/.assets/profile.ps1 $PS_PROFILE_PATH
# PowerShell functions
sudo \mkdir -p $PS_SCRIPTS_PATH
sudo \cp -f .config/.assets/ps_aliases_common.ps1 $PS_SCRIPTS_PATH
sudo \cp -f .config/.assets/ps_aliases_linux.ps1 $PS_SCRIPTS_PATH
# git functions
if type git &>/dev/null; then
  sudo \cp -f .config/.assets/ps_aliases_git.ps1 $PS_SCRIPTS_PATH
fi
# kubectl functions
if type -f kubectl &>/dev/null; then
  sudo \cp -f .config/.assets/ps_aliases_kubectl.ps1 $PS_SCRIPTS_PATH
  # add powershell kubectl autocompletion
  cat <<'EOF' | pwsh -nop -c -
$kctl = Get-Command kubectl -All | Where-Object -Property Version | Select-Object -First 1 -ExpandProperty Source
(& $kctl completion powershell).Replace("'kubectl'", "'k'") >$PROFILE.CurrentUserAllHosts'
EOF
fi