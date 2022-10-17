#!/bin/bash
: '
sudo .config/linux/scripts/install_pwsh.sh
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script with sudo!\e[0m'
  exit 1
fi

APP='pwsh'
while [[ -z $REL ]]; do
  REL=$(curl -sk https://api.github.com/repos/PowerShell/PowerShell/releases/latest | grep -Po '"tag_name": *"v\K.*?(?=")')
done

if type $APP &>/dev/null; then
  VER=$(pwsh -nop -c '$PSVersionTable.PSVersion.ToString()')
  if [ "$REL" = "$VER" ]; then
    echo "$APP v$VER is already latest"
    exit 0
  fi
fi

echo "Install $APP v$REL"
# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*\K(alpine|arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)

case $SYS_ID in
fedora)
  dnf install -y "https://github.com/PowerShell/PowerShell/releases/download/v${REL}/powershell-${REL}-1.rh.x86_64.rpm"
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  curl -Lsk -o powershell.deb "https://github.com/PowerShell/PowerShell/releases/download/v${REL}/powershell_${REL}-1.deb_amd64.deb"
  dpkg -i powershell.deb && rm -f powershell.deb
  ;;
alpine)
  apk add --no-cache \
    ca-certificates \
    less \
    ncurses-terminfo-base \
    krb5-libs \
    libgcc \
    libintl \
    libssl1.1 \
    libstdc++ \
    tzdata \
    userspace-rcu \
    zlib \
    icu-libs \
    curl
  apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache \
    lttng-ust
  while [[ ! -f powershell.tar.gz ]]; do
    curl -Lsk -o powershell.tar.gz "https://github.com/PowerShell/PowerShell/releases/download/v${REL}/powershell-${REL}-linux-alpine-x64.tar.gz"
  done
  mkdir -p /opt/microsoft/powershell/7
  tar zxf powershell.tar.gz -C /opt/microsoft/powershell/7 && rm -f powershell.tar.gz
  chmod +x /opt/microsoft/powershell/7/pwsh
  [ -f /usr/bin/pwsh ] || ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
  ;;
*)
  [ "$SYS_ID" = 'opensuse' ] && zypper in -y libicu || true
  while [[ ! -f powershell.tar.gz ]]; do
    curl -Lsk -o powershell.tar.gz "https://github.com/PowerShell/PowerShell/releases/download/v${REL}/powershell-${REL}-linux-x64.tar.gz"
  done
  mkdir -p /opt/microsoft/powershell/7
  tar zxf powershell.tar.gz -C /opt/microsoft/powershell/7 && rm -f powershell.tar.gz
  chmod +x /opt/microsoft/powershell/7/pwsh
  [ -f /usr/bin/pwsh ] || ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
  ;;
esac
