#!/bin/bash

clear

Infon()
{
 printf "\033[1;32m$@\033[0m"
}
Info()
{
 Infon "$@\n"
}
Error()
{
 printf "\033[1;31m$@\033[0m\n"
}
Error_n()
{
 Error "$@"
}
Error_s()
{
 Error "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - "
}
log_s()
{
 Info "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - "
}
log_n()
{
 Info "$@"
}
log_t()
{
 log_s
 Info "- - - $@"
 log_s
}

MIRROR="http://mirror.enginegp.ru"
VER=`cat /etc/issue.net | awk '{print $1$3}'`
echo "Detect OS Version: "$VER

case $(head -n1 /etc/issue | cut -f 1 -d ' ') in
    Debian)     type="deb" ;;
    Ubuntu)     type="ubn" ;;
    *)          type="rhl" ;;
esac

install_standart()
{
  rm -R $type.install.sh
  wget $MIRROR/install/$type.install.sh
  bash $type.install.sh
}

install_lite()
{
  rm -R $type.lite.install.sh
  wget $MIRROR/install/$type.lite.install.sh
  bash $type.lite.install.sh
}

# Меню установки игр
version_choice()
{
 clear
 log_t "Добро пожаловать в установщик EngineGP!"
 Info "Выберите версию панели:"
 Info "- 1 - Standart"
 Info "- 2 - Lite (alpha)"
 log_s
 Info
 read -p "Пожалуйста, введите пункт меню: " case
 case $case in
  1)
   install_standart
  ;;
  2)
   install_lite
  ;;
 esac
}

if [ deb = $type ] || [ deb = $type ]; then
  version_choice
 else
  echo "\033[1;31mДанная ОС временно не поддерживается!\033[0m"
  tput sgr0
fi

exit

